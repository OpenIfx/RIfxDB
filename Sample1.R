
library(IfxR)
ch <- IfxConnect( "SERVER=ids0;DATABASE=db1;HOST=127.0.0.1;SERVICE=9088;UID=informix;PWD=xxx;" )
tmp <- IfxQuery(ch, "select * from t1") 
res <- IfxFetchRows(ch)
print (res)

IfxColData(ch)

IfxClose(ch)