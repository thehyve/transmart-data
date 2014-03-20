package inc

/**
 * Created by carlos on 19/03/14.
 */
class ClientConfig {

    String username
    String password
    String baseUrl
    String authPath
    String jSessionId
    //String apiBasePath

    static ClientConfig read(String homeRelativePath) {
        String homeDir = System.getProperty('user.home')
        File file = new File(homeDir, homeRelativePath)
        def config = new ConfigSlurper().parse(file.toURL())
        new ClientConfig(config)
    }

    String getUrl(String path) {
        "$baseUrl$path"
    }

    String getAuthUrl() {
        getUrl(authPath)
    }

    Map getAuthBody() {
        [username: username, password: password]
    }
}
