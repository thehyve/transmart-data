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

import java.text.MessageFormat

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
Map featureLabelMap = featureMap.collectEntries { [ (it.key) : (it.value[1].toString().replace('_',' ')) ] }

def cookies = [
        "JSESSIONID=$jSessionId"
]
def cookie = cookies.join(';')

def subjectIdPrefix = datasetId.toUpperCase()
Closure<String> subjectIdFunction = { id ->
    MessageFormat.format("{0}-{1, number,00000000}", subjectIdPrefix, id)
}

List rows = getAllDataRows(datasetId, subjectIdFunction, cookie, features, featureMap)
File dataOutputFile = new File(baseFolder, "${datasetId}_data.txt")
//generates the data file
writeTsvFile(dataOutputFile, rows, getDataHeader(features, featureLabelMap))
println "${rows.size()} data rows written to file ${dataOutputFile.absolutePath}"

List mappingRows = getColumnMappingRows(dataOutputFile, features, featureMap, featureLabelMap, protocolMap)
File columnMappingFile = new File(baseFolder, "${datasetId}_columns.txt")
//generates the mapping file
writeTsvFile(columnMappingFile, mappingRows, getColumnMappingHeader())
println "Column mappings written to file ${columnMappingFile.absolutePath}"


/******* Methods ********/

List getColumnMappingRows(File dataFile, List features, Map featureMap, Map featureLabelMap, Map protocolMap) {

    Map protocolCategoryMap = protocolMap.keySet().collectEntries { [ (it) : (getProtocolCategory(it, protocolMap)) ] }
    String filename = dataFile.name
    String empty = ''
    int colIndex = 1
    List result = []
    result.add([filename, empty, colIndex++, 'SUBJ_ID', empty, empty ])

    List list = features.collect {
        List md = featureMap.get(it)
        String protocol = md[2] //parent
        String category = protocolCategoryMap.get(protocol)
        String label = featureLabelMap.get(it)
        [filename, category, colIndex++, featureLabelMap.get(it), empty, empty]
    }

    result.addAll(list)

    result
}

def getColumnMappingHeader() {
    [
            'Filename',
            'Category Code',
            'Column Number',
            'Data Label',
            'Data Label Source',
            'Controlled Vocab Code',
    ]
}

String getAttributeFilter(List features) {
    String featureIds = features.join(',')
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
            if (line.startsWith("#")) {
                continue //commented
            }
            List entry = line.split('\t') as List
            result.put(entry[keyColumn], entry)
        }

    }
    result
}

List getAllDataRows(String datasetId, Closure<String> subjectIdFunction, String cookie, List features, Map featureMap) {
    List result = []
    String attributeFilter = getAttributeFilter(features)
    String dataUrl = "/api/v1/$datasetId?$attributeFilter"
    boolean done = false

    while (!done) {
        Map data = execute(dataUrl, cookie)
        result.addAll(data.items.collect { createDataRow(it, subjectIdFunction, features, featureMap) })

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

List createDataRow(Map inputRow, Closure<String> subjectIdFunction, List features, Map featureMap) {
    List result = []
    result.add subjectIdFunction(getRowId(inputRow))

    for (String attr: features) {
        result.add(getTargetValue(inputRow, attr, featureMap))
    }
    result
}

List getDataHeader(List features, Map featureLabelMap) {
    List result = []
    result.add 'Subject'
    result.addAll(features.collect { featureLabelMap.get(it) } )
    result
}

def getTargetValue(Map inputRow, String attr, Map featureMap) {
    String type = featureMap.get(attr)[3]
    Object inputValue = inputRow.get(attr)
    convertValue(inputValue, type)
}

def convertValue(Object inputValue, String molgenisType) {
    switch (molgenisType.toUpperCase()) {
        case 'BOOL':
            return Boolean.valueOf(inputValue.toString()) ? 1 : 0
        case 'DATE':
            return parseMillis(inputValue)
        case 'DATE_TIME':
            return parseMillis(inputValue)
        case 'CATEGORICAL':
        case 'XREF':
        case 'MREF':
            return inputValue.href
        default:
            return inputValue; //no conversion needed
    }
}

def parseMillis(String value) {
    //example date: '1986-08-27T00:00:00+0200'
    Date.parse("yyyy-MM-dd'T'HH:mm:ssZ", value).time
}

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

/******* Methods to move to common script ********/

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

def asTsv(List entry) {
    entry.join('\t')
}

def writeTsvFile(File file, List entries, List header) {
    file.withWriter { out ->
        out.println asTsv(header)
        entries.each { List line ->
            out.println(asTsv(line))
        }
    }
}
