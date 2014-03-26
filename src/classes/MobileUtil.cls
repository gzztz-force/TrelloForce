public class MobileUtil
{
    public static Boolean isMobileBroswer(PageReference pageRef)
    {
        String userAgent = pageRef.getHeaders().get('USER-AGENT');

        // Some devices use custom headers for the user-agent.
        if (userAgent == null || userAgent.length() == 0)
        {
            userAgent = pageRef.getHeaders().get('HTTP_X_OPERAMINI_PHONE_UA');
        }
        if (userAgent == null || userAgent.length() == 0)
        {
            userAgent = pageRef.getHeaders().get('HTTP_X_SKYFIRE_PHONE');
        }

        // Using (?i) case insensitive mode.
        String deviceReg = '(?i)(iphone|ipod|ipad|blackberry|android|palm|windows\\s+ce)';
        String desktopReg = '(?i)(windows|linux|os\\s+[x9]|solaris|bsd)';
        String botReg = '(?i)(spider|crawl|slurp|bot)';

        Boolean isMobile = true, isDevice = false, isDesktop = false, isBot = false;

        Matcher m = Pattern.compile(deviceReg).matcher(userAgent);
        if (m.find())
        {
            isDevice = true;
        }
        else
        {
            m = Pattern.compile(desktopReg).matcher(userAgent);
            if (m.find()) isDesktop = true;

            m = Pattern.compile(botReg).matcher(userAgent);
            if (m.find()) isBot = true;
        }

        // Default is mobile - unless a desktop or bot user-agent identified.
        if (!isDevice && (isDesktop || isBot))
        {
            isMobile = false;
        }

        return isMobile;
    }
}