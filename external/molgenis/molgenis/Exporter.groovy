package molgenis

class Exporter {

    File baseFolder
    Dataset dataset
    List<Attribute> features

    private static def COLUMN_MAPPING_HEADER = [
        'Filename',
        'Category Code',
        'Column Number',
        'Data Label',
        'Data Label Source',
        'Controlled Vocab Code',
    ]

    void writeFiles(List rows) {
        baseFolder.mkdir()
        File dataFile = new File(baseFolder, "${dataset.id}_data.txt")
        writeTsvFile(dataFile, rows, getDataHeader())

        Map protocolMap = dataset.protocols.collectEntries { [(it.id) : (it)] }
        Map protocolCategoryMap = dataset.protocols.collectEntries { [ (it.id) : (getProtocolCategory(it.id, protocolMap)) ] }

        List mappingRows = getColumnMappingRows(dataFile, protocolCategoryMap)
        File columnMappingFile = new File(baseFolder, "${dataset.id}_columns.txt")
        writeTsvFile(columnMappingFile, mappingRows, COLUMN_MAPPING_HEADER)
    }

    private List getDataHeader() {
        List result = []
        result.add 'Subject'
        result.addAll(features.collect { it.label } )
        result
    }

    private def writeTsvFile(File file, List entries, List header) {
        file.withWriter { out ->
            out.println asTsv(header)
            entries.each { List line ->
                out.println(asTsv(line))
            }
        }
    }

    def asTsv(List entry) {
        entry.join('\t')
    }

    private List getColumnMappingRows(File dataFile, Map protocolCategoryMap) {

        String filename = dataFile.name
        String empty = ''
        int colIndex = 1
        List result = []
        result.add([filename, empty, colIndex++, 'SUBJ_ID', empty, empty ])

        List list = features.collect {
            String protocol = it.parentId
            String category = protocol ? protocolCategoryMap.get(protocol) : ''
            [filename, category, colIndex++, it.label, empty, empty]
        }

        result.addAll(list)

        result
    }

    private String getProtocolCategory(String protocolId, Map protocolMap) {

        Attribute protocol = protocolMap.get(protocolId)
        String label = protocol.label
        String result
        if (protocol.parentId) {
            String prefix = getProtocolCategory(protocol.parentId, protocolMap)
            result = "${prefix}+${label}"
        } else {
            result = label
        }

        result
    }

}
