package molgenis

import inc.Client

class MolgenisService {

    Client client
//    Dataset dataset
//    List<Attribute> selectedFeatures

    List<Dataset> getAllDatasets() {
        Map md = client.get('/api/v1/dataset')
        List list = md.items
        list.collect { new Dataset(id: it.Identifier, name: it.Name, href: it.href) }
    }

    Dataset getSelectedDataset() {
        getAllDatasets().find { it.id == 'celiacsprue' }
    }

    List<Attribute> selectFeatures(Dataset dataset) {
        if (dataset.protocols == null) {
            fillDatasetAttributes(dataset)
        }
        dataset.features
    }

    List getAllData(Dataset dataset, List<Attribute> features, Closure<List> rowCreator) {
        List result = []
        String attributeFilter = getAttributeFilter(features)
        String dataUrl = "/api/v1/${dataset.id}?$attributeFilter"
        boolean done = false

        while (!done) {
            Map data = client.get(dataUrl)
            result.addAll(data.items.collect { rowCreator.call( it ) })

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

    private String getAttributeFilter(List<Attribute> features) {
        String featureIds =  features.collect { it.id } join ','
        "attributes=$featureIds"
    }

    private void fillDatasetAttributes(Dataset dataset) {
        Map rootMetadata = client.get("/api/v1/${dataset.id}/meta")
        Set rootAttributeIds = rootMetadata.attributes.collect { it.key } as Set
        Map map = getAllAttributes(dataset, rootAttributeIds)

        dataset.protocols = []
        dataset.features = []
        collectEntries(map, dataset.protocols, dataset.features, rootAttributeIds, null)
    }

    private void collectEntries(Map attributeMap, List protocols, List features, Set currentAttrs, String parentProtocol) {

        for (String attrId: currentAttrs) {
            Map md = attributeMap.get(attrId)
            if (md == null) {
                throw new IllegalArgumentException("No metadata collected for attribute $attrId")
            }

            Attribute attribute = new Attribute(
                    id: attrId,
                    label: md.label.toString().replace('_', ' '),
                    parentId: parentProtocol,
                    type: md.fieldType)

            if (attribute.isProtocol()) {
                //adds protocol entries
                protocols.add(attribute)

                Set subs = md.attributes*.href.collect { getAttrName(it) }
                //recurse into collectEntries
                collectEntries(attributeMap, protocols, features, subs, attrId)
            } else {
                //adds feature entries
                features.add(attribute)
            }
        }
    }

    private Map getAllAttributes(Dataset dataset, Set rootAttributes) {

        Map result = [:]
        Set visited = new HashSet()
        for (String attr: rootAttributes) {
            result.putAll(getMetadataFor(dataset, attr, visited))
        }

        result
    }

    static int getObservationSetId(Map row) {
        String href = row.href
        Integer.parseInt(href.substring(href.lastIndexOf('/') + 1))
    }

    /**
     * Recursively gets metadata for the given attribute
     * @param dataset
     * @param attr attribute we want to get metadata for (recursively)
     * @param visited already visited attributes (to be modified)
     * @return
     */
    private Map getMetadataFor(Dataset dataset, String attr, Set visited) {
        Map result = [:]
        Map metadata = client.get("/api/v1/${dataset.id}/meta/$attr")
        result.put(attr, metadata)
        visited.add(attr)

        if (metadata.fieldType == 'COMPOUND') {
            List hrefs = metadata.attributes*.href as List
            Set subs = hrefs.collect { getAttrName(it) } as Set
            subs.removeAll(visited)

            for (String sub: subs) {
                result.putAll(getMetadataFor(dataset, sub, visited))
            }
        }
        result
    }

    private String getAttrName(String path) {
        path.substring(path.lastIndexOf('/') + 1)
    }

}
