public class JsonParserAndGenerator
{
    public static JSONParser parseJson(HttpResponse response)
    {
    	String body = replaceRelationFieldSuffix(replaceCustomFieldSuffix(response.getBody()));
        JSONParser parser = JSON.createParser(body);

        do
        {
            parser.nextToken();
        }
        while(parser.hasCurrentToken() && !'records'.equals(parser.getCurrentName()));

        parser.nextToken();

        return parser;
    }

    private static String replaceCustomFieldSuffix(String body)
    {
        //regex not thoroughly tested
        return body.replaceAll('_c"\\s*:', 'c" :');
    }

    private static String replaceRelationFieldSuffix(String body)
    {
        return body.replaceAll('_r"\\s*:', 'r" :');
    }
}