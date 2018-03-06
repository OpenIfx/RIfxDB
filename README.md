# IfxR
Informix native R driver
  
## Project Status : **Alpha**
.




### System setup to create the package
#### Windows
* [Install R](https://cran.r-project.org/)
* [Rtools](https://cran.rstudio.com/bin/windows/Rtools/) (GNU C/C++ compiler is part of it. **FYI**: I may advice it to be installed at default location which is **C:\Rtools**, to avoid extra build setup)
* [LaTeX](https://miktex.org/download) (To create R manuals; a complete build of R including PDF manuals too)
* [RStudio](https://www.rstudio.com/) (Optional: it is convenient to use, but no need of it if you plan to use only command line build.)



#### Linux
TODO: 


#### Experimental ....

#### Database setup
```sql
-- drop table t1;
create table t1 ( c1 int, c2 char(20), c3 int, c4 int ) ;
insert into t1 values( 1, 'Sunday', 101, 201 );
insert into t1 values( 2, 'Monday', 102, 202 );
insert into t1 values( 3, 'Tuesday', 103, 203 );
insert into t1 values( 4, 'Wednesday', 104, 204 );
insert into t1 values( 5, 'Thursday', 105, 2005 );
insert into t1 values( 6, 'Friday', 106, 206 );
insert into t1 values( 7, 'Saturday', 107, 207 );
```

####  Build the driver on windows, and then ....
```R
> library(IfxR)
> ch <- IfxConnect( "SERVER=ids0;DATABASE=db1;HOST=127.0.0.1;SERVICE=9088;UID=informix;PWD=xxxx;" )
> tmp <- IfxQuery(ch, "select * from t1") 
> res <- IfxFetchRows(ch)
> print (res)
$data
$data[[1]]
[1] 1 2 3 4 5 6 7

$data[[2]]
[1] "Sunday              " "Monday              " "Tuesday             " "Wednesday           "
[5] "Thursday            " "Friday              " "Saturday            "

$data[[3]]
[1] 101 102 103 104 105 106 107

$data[[4]]
[1]  201  202  203  204 2005  206  207


$stat
[1] 1

> IfxClose(ch)
> 
```



