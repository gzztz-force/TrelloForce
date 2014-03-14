/*
* represents a 2-division table, used with google chart api or Highchart
*/
public class ChartTable
{
    private Map<String, RowInfo> rowIndex;
    private Map<String, Integer> columnIndex;

    public ChartTable()
    {
        Columns = new List<String>();
        Rows = new List<RowInfo>();
        rowIndex = new Map<String, RowInfo>();
        columnIndex = new Map<String, Integer>();
        Cumulative = false;
    }

    public Boolean Cumulative { get; set; }
    public List<String> Columns { get; set; }
    public List<RowInfo> Rows { get; set; }

    public void addValue(String key, String column, Decimal value)
    {
        Integer columnIndex = getColumnIndex(column);
        if(columnIndex == -1)
        {
            addColumn(column);
            columnIndex = Columns.size() - 1;
        }

        RowInfo foundRow = null;
        if(rowIndex.containsKey(key))
        {
            foundRow = rowIndex.get(key);
        }
        if(foundRow == null)
        {
            foundRow = new RowInfo(key, Columns.size());
            foundRow.Cumulative = Cumulative;
            Rows.add(foundRow);
            rowIndex.put(key, foundRow);
        }

        foundRow.addValue(columnIndex, value);
    }

    public void addColumn(String columnName)
    {
         if(!columnIndex.containsKey(columnName))
         {
             Columns.add(columnName);
             columnIndex.put(columnName, Columns.size() - 1);
         }
    }

    private Integer getColumnIndex(String columnName)
    {
        if(columnIndex.containsKey(columnName))
        {
            return columnIndex.get(columnName);
        }
        else
        {
            for(Integer i = 0; i < Columns.size(); i++)
            {
                if(Columns[i] == columnName)
                {
                    columnIndex.put(columnName, i);
                    return i;
                }
            }
        }
        return -1;
    }

    public class RowInfo
    {
        public RowInfo(String key)
        {
            this.PrimaryKey = key;
            Cells = new List<Decimal>();
            Cumulative = false;
            Visible = true;
        }

        public RowInfo(String key, Integer columnCount)
        {
            this(key);
            for(Integer i = 0; i < columnCount; i++)
            {
                Cells.add(0);
            }
        }

        public Boolean Cumulative { get; set; }
        public String PrimaryKey { get; set; }
        public List<Decimal> Cells { get ;set; }
        public Boolean Visible { get; set; }

        public void addValue(Integer columnIndex, Decimal value)
        {
            if(value != null)
            {
                while(Cells.size() <= columnIndex)
                {
                    Cells.add(0);
                }
                if(Cumulative)
                {
                    Cells[columnIndex] += value;
                }
                else
                {
                    Cells[columnIndex] = value;
                }
            }
        }
    }

    @isTest
    static void testChartTable()
    {
        ChartTable table = new ChartTable();
        table.addValue('key', 'column1', 1);

        System.assertEquals(1, table.Columns.size());
        System.assertEquals(1, table.Rows.size());
    }
}