#!/usr/bin/groovy
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
import inc.*
import molgenis.*

import java.text.MessageFormat

if (args.length < 1) {
    println "Usage exportMolgenisData.groovy <targetFolder>"
    return 1
}

File baseFolder = new File(args[0])

ClientConfig config = ClientConfig.read('.transmart/molgenis.groovy')
Client client = Client.createWithCookie(config)
MolgenisService svc = new MolgenisService(client: client)

Dataset dataset = svc.getSelectedDataset()
//println dataset
List<Attribute> features = svc.selectFeatures(dataset)
//println features
//println dataset.protocols

String subjectIdPrefix = dataset.id.toUpperCase()

Closure<List> rowCreator = { Map input ->
    int id = MolgenisService.getObservationSetId(input)
    String subjectId = MessageFormat.format("{0}-{1, number,00000000}", subjectIdPrefix, id)
    List row = [ subjectId ]
    row.addAll(features.collect { it.getValue(input) })
    row
}

List dataRows = svc.getAllData(dataset, features, rowCreator)
//println dataRows.size()
Exporter exporter = new Exporter(dataset: dataset, features: features, baseFolder: baseFolder)
exporter.writeFiles(dataRows)



