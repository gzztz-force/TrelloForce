/*
 * Creates a section of javascript to generate the Highchart with the given data
 */
public class ChartBuilder
{
    public ChartBuilder(ChartTable table)
    {
        this.Data = table;
    }

    public ChartTable Data { get; set; }


    public String getColumns()
    {
        String result = '';
        for(String column : Data.Columns)
        {
            result += '"' + column + '",';
        }
        if(result.endsWith(','))
        {
            result = result.substring(0, result.length() - 1);
        }
        return result;
    }
    
    public String getRows()
    {
        String result = '';
        for(ChartTable.RowInfo row : Data.Rows)
        {
            result += buildRow(row) + ',';
        }
        if(result.endsWith(','))
        {
            result = result.substring(0, result.length() - 1);
        }
        return result;
    }
    
    public String buildRow(ChartTable.RowInfo row)
    {
        String result = '{' +
                        'name: "' + row.PrimaryKey + '",' +
                        'data: [';
        for(Decimal cell : row.Cells)
        {
            result += cell + ',';
        }
        if(result.endsWith(','))
        {
            result = result.substring(0, result.length() - 1);
        }
        result += '], color: getUserColor("' + row.PrimaryKey + '"), visible: ' + ((row.Visible) ? 'true' : 'false') + '}';
        return result;
    }
    
    @isTest
    static void testChartBuilder()
    {
        ChartTable table = new ChartTable();
        table.addValue('key', 'column1', 1);
        ChartBuilder builder = new ChartBuilder(table);
        System.assert(builder.getColumns() != null);
        System.assert(builder.getRows() != null);
    }
}