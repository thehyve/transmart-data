package inc

@groovy.lang.Grapes([
@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.6' ),
])
import groovyx.net.http.ContentType
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import org.apache.http.impl.client.BasicCookieStore

/**
 * Created by carlos on 19/03/14.
 */
class Client {

    ClientConfig config
    HTTPBuilder http
    Map cookies

    static Client createWithCookie(ClientConfig config) {
        Map cookies = [
                JSESSIONID: config.jSessionId
        ]
        HTTPBuilder http = new HTTPBuilder(config.baseUrl)
        new Client(config: config, http: http, cookies:  cookies)
    }

    /*
    static Client createAndAuthenticate(ClientConfig config) {
        def cookieStore = new BasicCookieStore()
        def http = new HTTPBuilder(config.baseUrl)

        http.post(path: config.authPath, body: config.authBody) { resp, body ->
            println resp.statusLine
            println body
            //println resp.headers.iterator() as List
        }
    }*/

    private String getCookieString() {
        cookies.collect { "${it.key}=${it.value}" } join(';')
    }

    def get(String path) throws IOException {
        def result
        http.request(Method.GET) {
            uri.path = path
            headers['Cookie'] = getCookieString()

            response.success = { resp, json ->
                assert resp.statusLine.statusCode == 200
                result = json
            }

            response.failure = { resp ->
                throw new IOException(path + ": "+ resp.statusLine.toString())
            }
        }

        result
    }

}
