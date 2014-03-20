package molgenis

//@groovy.transform.ToString
class Dataset {
    String id
    String name
    String href

    List<Attribute> protocols
    List<Attribute> features
}
