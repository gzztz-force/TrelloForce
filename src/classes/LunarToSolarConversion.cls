/*
 * Convert a lunar date to a solar date.
 */
public class LunarToSolarConversion
{
    private final static List<Integer> MONTH_DAYS = new List<Integer> { 29, 30 };
    private final static List<List<Integer>> DAYS_MONTH = new List<List<Integer>>{
                                                  new List<Integer>{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
                                                  new List<Integer>{ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
                                              };
    private final static List<List<Integer>> DATAS = new List<List<Integer>>{
                                             new List<Integer>{ 23, 3, 2, 17, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0 },
                                             new List<Integer>{ 41, 0, 4, 23, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1 },
                                             new List<Integer>{ 30, 7, 5, 28, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 49, 0, 6, 33, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 38, 0, 0, 38, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 26, 6, 2, 44, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 45, 0, 3, 49, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 35, 0, 4, 54, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 24, 4, 5, 59, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 43, 0, 0, 5, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 32, 0, 1, 10, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 21, 2, 2, 15, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 40, 0, 3, 20, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 28, 7, 5, 26, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 47, 0, 6, 31, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 36, 0, 0, 36, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 26, 5, 1, 41, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 44, 0, 3, 47, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 33, 0, 4, 52, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0 },
                                             new List<Integer>{ 23, 3, 5, 57, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1 },
                                             new List<Integer>{ 42, 0, 6, 2, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1 },
                                             new List<Integer>{ 30, 8, 1, 8, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 48, 0, 2, 13, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 38, 0, 3, 18, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 27, 6, 4, 23, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 45, 0, 6, 29, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 35, 0, 0, 34, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 24, 4, 1, 39, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0 },
                                             new List<Integer>{ 43, 0, 2, 44, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0 },
                                             new List<Integer>{ 32, 0, 4, 50, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 20, 3, 5, 55, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0 },
                                             new List<Integer>{ 39, 0, 6, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 29, 7, 0, 5, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 47, 0, 2, 11, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 36, 0, 3, 16, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0 },
                                             new List<Integer>{ 26, 5, 4, 21, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1 },
                                             new List<Integer>{ 45, 0, 5, 26, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 33, 0, 0, 32, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 22, 4, 1, 37, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 41, 0, 2, 42, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 30, 8, 3, 47, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1 },
                                             new List<Integer>{ 48, 0, 5, 53, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1 },
                                             new List<Integer>{ 37, 0, 6, 58, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 27, 6, 0, 3, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0 },
                                             new List<Integer>{ 46, 0, 1, 8, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0 },
                                             new List<Integer>{ 35, 0, 3, 14, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1 },
                                             new List<Integer>{ 24, 4, 4, 19, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1 },
                                             new List<Integer>{ 43, 0, 5, 24, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1 },
                                             new List<Integer>{ 32, 10, 6, 29, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 50, 0, 1, 35, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 39, 0, 2, 40, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1 },
                                             new List<Integer>{ 28, 6, 3, 45, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0 },
                                             new List<Integer>{ 47, 0, 4, 50, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 36, 0, 6, 56, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0 },
                                             new List<Integer>{ 26, 5, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1 },
                                             new List<Integer>{ 45, 0, 1, 6, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0 },
                                             new List<Integer>{ 34, 0, 2, 11, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0 },
                                             new List<Integer>{ 22, 3, 4, 17, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 40, 0, 5, 22, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 30, 8, 6, 27, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1 },
                                             new List<Integer>{ 49, 0, 0, 32, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1 },
                                             new List<Integer>{ 37, 0, 2, 38, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 27, 5, 3, 43, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 46, 0, 4, 48, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1 },
                                             new List<Integer>{ 35, 0, 5, 53, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 23, 4, 0, 59, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 42, 0, 1, 4, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 31, 0, 2, 9, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 21, 2, 3, 14, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 39, 0, 5, 20, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 28, 7, 6, 25, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 48, 0, 0, 30, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 37, 0, 1, 35, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1 },
                                             new List<Integer>{ 25, 5, 3, 41, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 44, 0, 4, 46, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1 },
                                             new List<Integer>{ 33, 0, 5, 51, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 22, 4, 6, 56, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 40, 0, 1, 2, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 30, 9, 2, 7, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 49, 0, 3, 12, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 38, 0, 4, 17, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0 },
                                             new List<Integer>{ 27, 6, 6, 23, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1 },
                                             new List<Integer>{ 46, 0, 0, 28, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0 },
                                             new List<Integer>{ 35, 0, 1, 33, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0 },
                                             new List<Integer>{ 24, 4, 2, 38, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 42, 0, 4, 44, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 31, 0, 5, 49, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0 },
                                             new List<Integer>{ 21, 2, 6, 54, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1 },
                                             new List<Integer>{ 40, 0, 0, 59, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 28, 6, 2, 5, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0 },
                                             new List<Integer>{ 47, 0, 3, 10, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1 },
                                             new List<Integer>{ 36, 0, 4, 15, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1 },
                                             new List<Integer>{ 25, 5, 5, 20, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0 },
                                             new List<Integer>{ 43, 0, 0, 26, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1 },
                                             new List<Integer>{ 32, 0, 1, 31, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0 },
                                             new List<Integer>{ 22, 3, 2, 36, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0 }
                                         };
    /*
     * get the solar date according the lunar date （the date must years between 1936 and 2028）
     */
    public static Date getSolarDate(Integer year, Integer month, Integer day)
    {
        Integer index = year - 1936;
        Integer endIndex = month;

        /*DATA[index][1]某年闰几月  0表示没有润月*/
        if ((DATAS[index][1] != 0) && (month > DATAS[index][1]))
        {
            endIndex++;
        }

        Integer dayNum = 0;

        for (Integer i = 0; i < (endIndex - 1); i++)
        {
            dayNum += MONTH_DAYS[DATAS[index][4 + i]];
        }

        dayNum += day;
        dayNum += DATAS[index][0];

        Integer year_days = 365;

        if (Date.isLeapYear(year))
        {
            year_days = 366;
        }

        if (dayNum > year_days)
        {
            year++;
            dayNum -= year_days;
        }

        month = 1;

        List<Integer> dayOfMonth = DAYS_MONTH[0];

        if (Date.isLeapYear(year))
        {
            dayOfMonth = DAYS_MONTH[1];
        }

        Integer i = 0;

        for (; i < 12; i++)
        {
            dayNum -= dayOfMonth[i];

            if (dayNum <= 0)
            {
                break;
            }

            month++;
        }

        day = dayOfMonth[i] + dayNum;

        return Date.parse(month + '/' + day + '/' + year);
    }

    /*
     * Judge some year's some month is big month or small month
     */
    public static Boolean isBigMonth(Integer year, Integer month)
    {
        Date thisMonth = getSolarDate(year, month, 1);
        Date nextMonth = getSolarDate(year, month + 1, 1);
        Integer diffDays = thisMonth.daysBetween(nextMonth);
        if(diffDays == 30)
            return true;
        else
            return false;
    }

    /*
     * Get birthday this year solar date
    */
    public static Date getBirthdayThisYear(Integer month, Integer day, String type)
    {
        Date solarBirthday;
        if(type == 'Lunar' && isBigMonth(Date.today().year(), month) == false && day == 30)
        {
            solarBirthday = getSolarDate(Date.today().year(), month, day - 1);
        }
        else
        {
            if(type == 'Solar')
            {
                solarBirthday = Date.valueOf(Date.today().year() + '-' + month + '-' + day);
            }
            else
            {
                solarBirthday = getSolarDate(Date.today().year(), month, day);
            }
        }
        return solarBirthday;
    }

    /*
     * Get birthday next year solar date
    */
    public static Date getBirthdayNextYear(Integer month, Integer day, String type)
    {
        Date solarBirthday;
        if(type == 'Lunar' && isBigMonth(Date.today().addYears(1).year(), month) == false && day == 30)
        {
            solarBirthday = getSolarDate(Date.today().addYears(1).year(), month, day - 1);
        }
        else
        {
            if(type == 'Solar')
            {
                solarBirthday = Date.valueOf(Date.today().addYears(1).year() + '-' + month + '-' + day);
            }
            else
            {
                solarBirthday = getSolarDate(Date.today().addYears(1).year(), month, day);
            }
        }
        return solarBirthday;
    }
}