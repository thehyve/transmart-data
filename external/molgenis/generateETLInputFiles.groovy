#!/usr/bin/groovy

import groovy.json.JsonBuilder
@groovy.lang.Grapes([
@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.6' ),
@Grab(group='commons-beanutils', module='commons-beanutils', version='1.8.3'),
@Grab(group='log4j', module='log4j', version='1.2.17'),
@Grab(group='org.slf4j', module='slf4j-log4j12', version='1.7.5'),
@Grab(group='org.slf4j', module='jcl-over-slf4j', version='1.7.5'),
])
import groovyx.net.http.ContentType
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import org.apache.http.HttpResponse
import org.apache.http.impl.client.BasicCookieStore
import org.apache.log4j.Logger
import org.apache.log4j.PropertyConfigurator
import org.codehaus.groovy.util.StringUtil

if (args.length < 3) {
    println "Usage generateETLInputFiles.groovy jSessionId datasetId folder"
    return 1
}

String jSessionId = args[0]
String datasetId = args[1]
File baseFolder = new File(args[2])

Map protocolMap = readTsvFileAsMap(new File(baseFolder, "${datasetId}_protocols.tsv"), 0)
Map featureMap = readTsvFileAsMap(new File(baseFolder, "${datasetId}_features.tsv"), 0)

List features = featureMap.keySet() as List
Map protocolCategoryMap = protocolMap.keySet().collectEntries { [ (it) : (getProtocolCategory(it, protocolMap)) ] }
Map featureLabelMap = featureMap.collectEntries { [ (it.key) : (it.value[1].toString().replace('_',' ')) ] }

//println protocolCategoryMap
//println featureLabelMap

def cookies = [
        "JSESSIONID=$jSessionId"
]
def cookie = cookies.join(';')

def execute(String path, String cookie) throws IOException {
    def server = 'http://molgenis01.target.rug.nl'

    def http = new HTTPBuilder(server)
    def result

    http.request(Method.GET) {
        uri.path = path
        headers['Cookie'] = cookie

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

String getAttributeFilter(List features) {
    String featureIds = features.join(',')
    //"/api/v1/$datasetId?" +
    "attributes=$featureIds"
}

Map readTsvFileAsMap(File file, int keyColumn) {

    if (!file.exists()) {
        throw new IllegalArgumentException("File ${file.absolutePath} does not exist")
    }

    Map result = [:]

    file.withReader { reader ->
        reader.readLine() //skip header
        while (line = reader.readLine()) {
            List entry = line.split('\t') as List
            result.put(entry[keyColumn], entry)
        }

    }
    result
}

List getAllDataRows(String datasetId, String cookie, List features) {
    List result = []
    String attributeFilter = getAttributeFilter(features)
    String dataUrl = "/api/v1/$datasetId?$attributeFilter"
    boolean done = false
    String idPrefix = "${datasetId.toUpperCase()}_"

    while (!done) {
        Map data = execute(dataUrl, cookie)
    println data
        result.addAll(getDataRows(data), )

        String next = data.nextHref
        if (next) {
            //next batch
            dataUrl = "$next&$attributeFilter"
        } else {
            done = true
        }
    }

    result
}


List getDataRows(Map inputJson, String idPrefix) {
    List result = []

    result
}
/*
List createDataRow(String idPrefix, Map inputRow, List features, Map featureLabelMap) {
    List result = []


    result.add getRowId(inputRow)
    for (String feature: fea)

}

def getTargetValue(Map inputRow, String attr, Map featureMap) {

}
*/

int getRowId(Map row) {
    String href = row.href
    Integer.parseInt(href.substring(href.lastIndexOf('/') + 1))
}

String getProtocolCategory(String protocol, Map protocolMap) {

    List entry = protocolMap.get(protocol)

    String label = entry[1].toString().replace('_',' ')
    String parent =  entry[2].toString()

    String result
    if (isEmpty(parent)) {
        result = label
    } else {
        String prefix = getProtocolCategory(parent, protocolMap)
        result = "${prefix}+${label}"
    }

    result
}

boolean isEmpty(String str) {
    return !str || "null" == str || str.trim().length() == 0
}


