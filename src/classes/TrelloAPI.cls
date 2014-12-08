public with sharing class TrelloAPI
{
    private String key;
    private String token;
    private final String BOARDS_URL = 'https://api.trello.com/1/members/my/boards/all';
    private final String BOARD_CARDS_URL = 'https://api.trello.com/1/boards/{0}/cards';
    private final String BOARD_CHECKLISTS_URL = 'https://api.trello.com/1/boards/{0}/checklists'; 
    private final String BOARD_MEMBERS_URL = 'https://api.trello.com/1/boards/{0}/members';

    public TrelloAPI(String key, String token)
    {
        this.key = key;
        this.token = token;
    }

    public String createURL(String url, List<String> pathParams)
    {
        url += '?key=' + key + '&token=' + token;
        if (pathParams == null || pathParams.size() == 0) return url;
        String compiledUrl = String.format(url, pathParams);
        System.debug(compiledUrl);
        return compiledUrl;

    }

    public String getTrelloInfo(String url)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return response.getBody();
    }

    public List<TrelloModel.Board> getBoardInfo()
    {
        List<TrelloModel.Board> boards = (List<TrelloModel.Board>)JSON.deserialize(getTrelloInfo(createURL(BOARDS_URL, null)), List<TrelloModel.Board>.class);
        if(boards.size() == null)
        {
            TrelloModel.Board board = new TrelloModel.Board();
            boards.add(board);
        }
        return boards;
    }

    public List<TrelloModel.Card> getCardInfo(List<String> params)
    {
            return (List<TrelloModel.Card>)JSON.deserialize(getTrelloInfo(createURL(BOARD_CARDS_URL, params)), List<TrelloModel.Card>.class);
    }

    public List<TrelloModel.CheckList> getCheckListInfo(List<String> params)
    {
            return (List<TrelloModel.CheckList>)JSON.deserialize(getTrelloInfo(createURL(BOARD_CHECKLISTS_URL, params)), List<TrelloModel.CheckList>.class);       
    }

    public List<TrelloModel.Member> getAllMembers(List<String> params)
    {
            return (List<TrelloModel.Member>)JSON.deserialize(getTrelloInfo(createURL(BOARD_MEMBERS_URL, params)), List<TrelloModel.Member>.class);
    }

}