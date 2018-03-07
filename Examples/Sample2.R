# Rscript  Sample2.R 
library(IfxR)

ch <- IfxConnect( "SERVER=ids0;DATABASE=db1;HOST=127.0.0.1;SERVICE=9088;UID=informix;PWD=xxxx;" )

sql <- c( "create table t1 ( c1 int, c2 char(20), c3 int, c4 int ) ", 
"insert into t1 values( 1, 'Sunday', 101, 201 );", 
"insert into t1 values( 2, 'Monday', 102, 202 );", 
"insert into t1 values( 3, 'Tuesday', 103, 203 );", 
"insert into t1 values( 4, 'Wednesday', 104, 204 );", 
"insert into t1 values( 5, 'Thursday', 105, 2005 );", 
"insert into t1 values( 6, 'Friday', 106, 206 );", 
"insert into t1 values( 7, 'Saturday', 107, 207 );" )

s <- c("drop table t1;")


result = tryCatch({
  rc <- IfxQuery( ch, s )
  x <- sprintf( " [%d] %s", rc, s)  
  print( x )
}
,warning = function(w) 
{
  x <- sprintf("Warning: %s", s)
  print( x )
}
,error = function(e) 
{
  x <- sprintf("Error: %s", s)
  print( x )
}, 
finally = {}
)

for(s in sql)
{
  rc <- IfxQuery(ch, s) 
  x <- sprintf(" [%d] %s", rc, s)  
  print( x )
}

rc <- IfxQuery(ch, "select * from t1") 
res <- IfxFetchRows(ch)

print ( "****** The Select Output is ********" )
print (res)

IfxClose(ch)

