@[User::NewFilePath] = REPLACE(@[User::FilePath], ".xlsx", 
                  "_" + (DT_WSTR,4)YEAR(GETDATE()) + 
                  RIGHT("0" + (DT_WSTR,2)MONTH(GETDATE()),2) + 
                  RIGHT("0" + (DT_WSTR,2)DAY(GETDATE()),2) + "_" +
                  RIGHT("0" + (DT_WSTR,2)DATEPART(HOUR, GETDATE()),2) +
                  RIGHT("0" + (DT_WSTR,2)DATEPART(MINUTE, GETDATE()),2) +
                  RIGHT("0" + (DT_WSTR,2)DATEPART(SECOND, GETDATE()),2) +
                  ".xlsx")