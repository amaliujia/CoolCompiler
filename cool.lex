/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */

%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
    if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
        YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
          
extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval; 

/*
 *  Add Your own definitions here
 */ 
int comment_nesting = 0;
int escaped_flag = 0;

//buffer for string
void ppendToBuffer(char *text, int length);
char *last_text_token = NULL;
int last_text_token_len = 0;
int last_text_token_bufferSize = 0;
bool  stringErrorFlag = false;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-
LE              <=
CLASS           (?i:class)
INHERITS        (?i:inherits)
ELSE            (?i:else)
FI              (?i:fi)
IF              (?i:if)
IN              (?i:in)
LET             (?i:let)
LOOP            (?i:loop)
NOT             (?i:not)
POOL            (?i:pool)
THEN            (?i:then)
ISVOID          (?i:isvoid)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
OF              (?i:of)
NEW             (?i:new)
NEWLINE         \n
INT_CONST       [0-9]+
BOOL_CONST_TRUE     t(?i:rue)
BOOL_CONST_FALSE    f(?i:alse)
TYPEID          [A-Z][a-zA-Z0-9_]*
OBJECTID        [a-z][a-zA-Z0-9_]*
BLANK           \f|\r|\ |\t|\v|\n
NOTATION        "{"|"}"|"("|")"|";"|"."|":"|"~"|"@"|","|"="|"*"|"+"|"-"|"/"|"<"
%x comment_singleLine
%x comment_multiLine
%x string 
%x escape
%%
-- BEGIN(comment_singleLine);
<comment_singleLine>[^\n]*
<comment_singleLine>\n      curr_lineno++; BEGIN 0;

"(*"                        {comment_nesting++;BEGIN(comment_multiLine);}
<comment_multiLine>\(\*     {comment_nesting++;}
<comment_multiLine>\n       curr_lineno++;
<comment_multiLine><<EOF>>  {BEGIN 0; cool_yylval.error_msg="EOF in comment"; return ERROR;}
<comment_multiLine>\*\)     {comment_nesting--;if(comment_nesting == 0) BEGIN 0;}
<comment_multiLine>.
\*\)                        {cool_yylval.error_msg = "Unmatched *)"; return ERROR;}

{DARROW}        {return (DARROW);}
{ASSIGN}        {return (ASSIGN);}
{LE}            {return (LE);}
{CLASS}         {return (CLASS);}
{IN}            {return (IN);}
{INHERITS}      {return (INHERITS);}
{ELSE}          {return (ELSE);}
{FI}            {return (FI);}
{IF}            {return (IF);}
{LET}           {return (LET);}
{LOOP}          {return (LOOP);}
{NOT}           {return (NOT);}
{POOL}          {return (POOL);}
{THEN}          {return (THEN);}
{ISVOID}        {return (ISVOID);}
{WHILE}         {return (WHILE);}
{CASE}          {return (CASE);}
{ESAC}          {return (ESAC);}
{OF}                {return (OF);}
{NEW}               {return (NEW);}
{NEWLINE}           {curr_lineno++;}

{INT_CONST}         {cool_yylval.symbol = inttable.add_string(yytext);
                    return (INT_CONST);}
{BOOL_CONST_TRUE}       {cool_yylval.boolean = 1;
                        return (BOOL_CONST);}
{BOOL_CONST_FALSE}      {cool_yylval.boolean = 0;return (BOOL_CONST);}
{TYPEID}            {cool_yylval.symbol = inttable.add_string(yytext);return (TYPEID);}
{OBJECTID}          {cool_yylval.symbol = inttable.add_string(yytext); return (OBJECTID);}
{NOTATION}          {return *yytext;}

\"                  {BEGIN(string);}
<string>[^\\\"\n\0]         {ppendToBuffer(yytext, yyleng);}
<string>\n                  {
                            BEGIN(0);
                            cool_yylval.error_msg = "Unterminated string constant";
                            curr_lineno++;
                            if(last_text_token != NULL) free(last_text_token);
                                last_text_token = NULL;
                                last_text_token_len = 0;
                                last_text_token_bufferSize = 0;
                            return ERROR;
                            }

<string>\"              {
                                BEGIN(0);
                                if(stringErrorFlag)
                                {
                                    if(last_text_token != NULL){
                                        free(last_text_token);
                                    }
                                    last_text_token_len = 0;
                                    last_text_token_bufferSize = 0;
                                    last_text_token = NULL;
                                }else{
                                    if(last_text_token == NULL){
                                        cool_yylval.symbol = inttable.add_string("");
                                    }else{
                                        cool_yylval.symbol = inttable.add_string(last_text_token);
                                        free(last_text_token);
                                        last_text_token_len = 0;
                                        last_text_token_bufferSize = 0;
                                        last_text_token = NULL;
                                    }
                                    return (STR_CONST);
                                }
                            }


<string>\x00                {cool_yylval.error_msg = "String contains null character"; stringErrorFlag = true; return ERROR;}
<escape>\x00                {cool_yylval.error_msg = "String contains null character"; stringErrorFlag = true;BEGIN(string); return ERROR;}
<string><<EOF>>     {cool_yylval.error_msg = "String contains EOF character"; BEGIN(0); return ERROR;}
<escape><<EOF>>     {cool_yylval.error_msg = "String contains EOF character"; BEGIN(0); return ERROR;}
<string>\\                  {BEGIN(escape);}
<escape>\n                  {curr_lineno++;ppendToBuffer("\n",1);BEGIN(string);}
<escape>n                   {ppendToBuffer("\n",1);BEGIN(string);}
<escape>t                   {ppendToBuffer("\t",1);BEGIN(string);}
<escape>b                   {ppendToBuffer("\b",1);BEGIN(string);}
<escape>f                   {ppendToBuffer("\f",1);BEGIN(string);}
<escape>\\                  {ppendToBuffer("\\",1);BEGIN(string);}
<escape>.                   {ppendToBuffer(yytext,yyleng);BEGIN(string);}


{BLANK}
.                   { cool_yylval.error_msg = yytext; return ERROR; }
%%

void ppendToBuffer(char *text, int length)
{
    if(last_text_token == NULL)
    {
        last_text_token_bufferSize = 1024;
        last_text_token = (char *)calloc(1, 1024);
    }
    if((last_text_token_len + length) > 1024)
    {
        stringErrorFlag = true;
        cool_yylval.error_msg = "String constant too long";
        BEGIN(string);
        return ERROR;
    }
    //reaoolocate memory if necessary
    if((last_text_token_len + length) >= last_text_token_bufferSize)
    {
        last_text_token_bufferSize += 1024;
        last_text_token = (char *)realloc(last_text_token, last_text_token_bufferSize);
    }
    *(last_text_token + last_text_token_len) = *text;
    last_text_token_len += length;
}
