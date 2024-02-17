package de.mpiwg.fop.servlet;

import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.URIResolver;

/** URIResolver that calls a list of other URIResolvers until it finds one that works. 
 * For cases when you can set only one resolver but need more than one.
 * @author casties
 *
 */
public class ChainingURIResolver implements URIResolver {

    private URIResolver[] resolvers;
    
    /** Constructs a URIResolver that calls the given resolvers in turn until one returns a result.
     * 
     * @param resolvers
     */
    public ChainingURIResolver(URIResolver... resolvers) {
        this.resolvers = resolvers;
    }
    
    public Source resolve(String href, String base) throws TransformerException {
        Source s = null;
        // try all resolvers until we find one that works
        for (URIResolver r: resolvers) {
            s = r.resolve(href, base);
            if (s != null) {
                return s;
            }
        }
        // else return null
        return null;
    }

}
