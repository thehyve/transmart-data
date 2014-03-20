package molgenis

@groovy.transform.ToString
class Attribute {
    String id
    String label
    String parentId
    String type

    boolean isProtocol() {
        type == 'COMPOUND'
    }

    def getValue(Map inputRow) {
        convertValue(inputRow.get(id))
    }

    def convertValue(Object inputValue) {
        switch (type.toUpperCase()) {
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

    private def parseMillis(String value) {
        //example date: '1986-08-27T00:00:00+0200'
        Date.parse("yyyy-MM-dd'T'HH:mm:ssZ", value).time
    }

}
