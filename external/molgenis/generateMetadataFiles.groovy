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

if (args.length < 2) {
    println "Usage generateMetadataFiles.groovy jSessionId datasetId [targetFolder]"
    return 1
}

String jSessionId = args[0]
String datasetId = args[1]

def cookies = [
        "JSESSIONID=$jSessionId"
]
def cookie = cookies.join(';')


//gets metadata for the dataset
def rootMetadata = execute("/api/v1/$datasetId/meta", cookie)
//collects the top level attributes
Set rootAttrs = rootMetadata.attributes.collect { it.key } as Set
//gets a Map of String -> metadata Map for all attributes in the dataset
def attributeMap = getCompleteMetadata(datasetId, cookie, rootAttrs)
//collects the top level protocols
Set rootProtocols = attributeMap.findAll { it.key in rootAttrs && isProtocol(it.value) } .keySet()

List protocolEntries = []
List featureEntries = []

collectEntries(attributeMap, protocolEntries, featureEntries, rootProtocols, null)

//println protocolEntries
//println featureEntries

File targetFolder
if (args.length > 2) {
    targetFolder = new File(args[2])
} else {
    targetFolder = new File(File.createTempFile('dummy', '').parentFile, "molgenisDataOutput-${System.currentTimeMillis()}")
}

targetFolder.mkdirs()

File protocolsFile = new File(targetFolder, "${datasetId}_protocols.tsv")
File featuresFile = new File(targetFolder, "${datasetId}_features.tsv")

println "Output folder is $targetFolder"

writeTsvFile(protocolsFile, protocolEntries, ['Name','Label','Parent'])

writeTsvFile(featuresFile, featureEntries, ['Name','Label','Parent','Type'])

/**
 * Recursively populates the given protocol and feature entry lists.
 *
 * @param attributeMap map containing the metadata of all attributes
 * @param protocolEntries accumulated protocol entries
 * @param featureEntries accumulated feature entries
 * @param currentAttrs current attributes to be processed
 * @param parentProtocol parent protocol of the current attributes
 */
void collectEntries(Map attributeMap, List protocolEntries, List featureEntries, Set currentAttrs, String parentProtocol) {

    for (String attr: currentAttrs) {
        Map md = attributeMap.get(attr)
        if (md == null) {
            throw new IllegalArgumentException("No metadata collected for attribute $attr")
        }

        if (isProtocol(md)) {
            //adds protocol entries
            protocolEntries.add([attr, md.label, parentProtocol])
            Set subs = md.attributes*.href.collect { getAttrName(it) }
            //recurse into collectEntries
            collectEntries(attributeMap, protocolEntries, featureEntries, subs, attr)
        } else {
            //adds feature entries
            featureEntries.add([attr, md.label, parentProtocol, md.fieldType, null])
        }
    }
}

/**
 * Retrieves the complete metadata for given dataset.
 * Each entry key is the attribute (protocol or feature) name, and value is the json map as returned from the REST call
 * @param datasetId
 * @param cookie
 * @param attrs
 * @return Map of [attribute key -> metadata json Map]
 */
Map getCompleteMetadata(String datasetId, String cookie, Set attrs) {

    Map result = [:]
    Set visited = new HashSet()
    for (String attr: attrs) {
        result.putAll(getMetadataFor(datasetId, attr, visited, cookie))
    }

    result
}

/**
 * Recursively gets metadata for the given attribute
 * @param datasetId
 * @param attr attribute we want to get metadata for (recursively)
 * @param visited already visited attributes (to be modified)
 * @param cookie
 * @return
 */
def getMetadataFor(String datasetId, String attr, Set visited, String cookie) {
    Map result = [:]
    Map metadata = execute("/api/v1/$datasetId/meta/$attr", cookie)
    result.put(attr, metadata)
    visited.add(attr)

    if (metadata.fieldType == 'COMPOUND') {
        List hrefs = metadata.attributes*.href as List
        Set subs = hrefs.collect { getAttrName(it) } as Set
        subs.removeAll(visited)

        for (String sub: subs) {
            result.putAll(getMetadataFor(datasetId, sub, visited, cookie))
        }
    }
    result
}

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

def getAttrName(String path) {
    path.substring(path.lastIndexOf('/') + 1)
}

def isProtocol(Map md) {
    md.fieldType == 'COMPOUND'
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



