/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package de.mpiwg.fop.servlet;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParserFactory;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.URIResolver;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamSource;

import org.apache.commons.io.output.ByteArrayOutputStream;
import org.apache.commons.logging.impl.SimpleLog;
import org.apache.fop.apps.FOPException;
import org.apache.fop.apps.FOUserAgent;
import org.apache.fop.apps.Fop;
import org.apache.fop.apps.FopFactory;
import org.apache.fop.apps.MimeConstants;
import org.apache.xml.resolver.CatalogManager;
import org.apache.xml.resolver.tools.CatalogResolver;
import org.xml.sax.EntityResolver;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;

/**
 * Example servlet to generate a PDF from an VLP essay. <br/>
 * Servlet param is:
 * <ul>
 * <li>article: the ID of the VLP essay e.g. "art68"
 * </ul>
 * <br/>
 * Example URL: http://servername/fop/servlet/VLPEssayServlet?article=art68 <br/>
 * This will generate "art68.pdf" for download.
 * 
 * @author Apache FOP Development Team, Robert Casties (12/2008)
 */
public class VLPEssayServlet extends HttpServlet {

    private static final long serialVersionUID = 5433352980851431895L;

    /** Name of the parameter used for the XML file */
    protected static final String ID_REQUEST_PARAM = "article";

    /** Logger to give to FOP */
    protected SimpleLog log = null;
    /** The TransformerFactory used to create Transformer instances */
    protected TransformerFactory transFactory = null;
    /** The FopFactory used to create Fop instances */
    protected FopFactory fopFactory = null;
    /** URIResolver for use by this servlet */
    protected URIResolver uriResolver;
    protected EntityResolver entityResolver;

    protected static final String XSLT_NAME = "servlet-context://xml-to-pdf.xslt";
    protected static final String XML_BASE_URL = "https://vlp.mpiwg-berlin.mpg.de/essays/data/";
    protected static final String CATALOG_FILE = "WEB-INF/DTD/xml-catalog.xml";

    /**
     * {@inheritDoc}
     */
    public void init() throws ServletException {
        this.log = new SimpleLog("FOP/Servlet");
        log.setLevel(SimpleLog.LOG_LEVEL_DEBUG);
        URIResolver scr = new ServletContextURIResolver(getServletContext());
        // create xml catalog resolver
        String fn = getServletContext().getRealPath(CATALOG_FILE);
        CatalogManager ctm = new CatalogManager();
        ctm.setCatalogFiles(fn);
        URIResolver cr = new CatalogResolver(ctm);
        this.uriResolver = new ChainingURIResolver(scr, cr);
        // use CatalogResolver also as entity resolver
        this.entityResolver = new CatalogResolver(ctm);
        // create TransformerFactory
        this.transFactory = TransformerFactory.newInstance();
        this.transFactory.setURIResolver(this.uriResolver);
        // Configure FopFactory as desired
        this.fopFactory = FopFactory.newInstance();
        this.fopFactory.setURIResolver(this.uriResolver);
        configureFopFactory();
    }

    /**
     * This method is called right after the FopFactory is instantiated and can
     * be overridden by subclasses to perform additional configuration.
     */
    protected void configureFopFactory() {
        // Subclass and override this method to perform additional configuration
    }

    /**
     * {@inheritDoc}
     */
    public void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException {
        try {
            // Get parameters
            String idParam = request.getParameter(ID_REQUEST_PARAM);

            // Analyze parameters and decide with method to use
            if (idParam != null) {
                renderXML(idParam, XSLT_NAME, response);
            } else {
                response.setContentType("text/html");
                PrintWriter out = response.getWriter();
                out.println("<html><head><title>Error</title></head>\n"
                        + "<body><h1>FopServlet Error</h1><h3>No "
                        + "request param given.</body></html>");
            }
        } catch (Exception ex) {
            throw new ServletException(ex);
        }
    }

    /**
     * Converts a String parameter to a JAXP Source object.
     * 
     * @param param
     *            a String parameter
     * @return Source the generated Source object
     */
    protected Source convertString2Source(String param) {
        Source src;
        try {
            src = uriResolver.resolve(param, null);
        } catch (TransformerException e) {
            src = null;
        }
        if (src == null) {
            src = new StreamSource(new File(param));
        }
        return src;
    }

    private void sendPDF(byte[] content, String filename,
            HttpServletResponse response) throws IOException {
        // Send the result back to the client
        response.setContentType("application/pdf");
        if (filename == null) {
            filename = "essay.pdf";
        }
        response.addHeader("Content-Disposition", "attachment; filename=\""
                + filename + "\"");
        response.setContentLength(content.length);
        response.getOutputStream().write(content);
        response.getOutputStream().flush();
    }

    /**
     * Renders an XML file into a PDF file by applying a stylesheet that
     * converts the XML to XSL-FO. The PDF is written to a byte array that is
     * returned as the method's result.
     * 
     * @param articleID
     *            the ID of the XML article
     * @param xslt
     *            the XSLT file
     * @param response
     *            HTTP response object
     * @throws FOPException
     *             If an error occurs during the rendering of the XSL-FO
     * @throws TransformerException
     *             If an error occurs during XSL transformation
     * @throws IOException
     *             In case of an I/O problem
     */
    protected void renderXML(String articleID, String xslt,
            HttpServletResponse response) throws FOPException,
            TransformerException, IOException {

        // Setup sources
        String articleBase = XML_BASE_URL + articleID + "/";
        Source xmlSrc = new StreamSource(articleBase + "essay.xml");

        Source xsltSrc = convertString2Source(xslt);

        // Setup the XSL transformation
        Transformer transformer = this.transFactory.newTransformer(xsltSrc);
        // ((Controller) transformer).
        transformer.setURIResolver(this.uriResolver);

        // Start transformation and rendering process
        String outFilename = articleID + ".pdf";
        render(xmlSrc, articleBase, transformer, response, outFilename);
    }

    /**
     * Renders an input file (XML or XSL-FO) into a PDF file. It uses the JAXP
     * transformer given to optionally transform the input document to XSL-FO.
     * The transformer may be an identity transformer in which case the input
     * must already be XSL-FO. The PDF is written to a byte array that is
     * returned as the method's result.
     * 
     * @param src
     *            Input XML or XSL-FO
     * @param baseUrl
     *            base URL for XSLT
     * @param transformer
     *            Transformer to use for optional transformation
     * @param response
     *            HTTP response object
     * @param outFilename
     * @throws FOPException
     *             If an error occurs during the rendering of the XSL-FO
     * @throws TransformerException
     *             If an error occurs during XSL transformation
     * @throws IOException
     *             In case of an I/O problem
     */
    protected void render(Source src, String baseUrl, Transformer transformer,
            HttpServletResponse response, String outFilename)
            throws FOPException, TransformerException, IOException {

        FOUserAgent foUserAgent = getFOUserAgent();
        foUserAgent.setBaseURL(baseUrl);
        foUserAgent.setURIResolver(this.uriResolver);

        // Setup output
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            // Setup FOP
            Fop fop = fopFactory.newFop(MimeConstants.MIME_PDF, foUserAgent,
                    out);

            // set up parser with our EntityResolver
            SAXParserFactory spf = SAXParserFactory.newInstance();
            spf.setNamespaceAware(true);
            XMLReader xmlReader = spf.newSAXParser().getXMLReader();
            xmlReader.setEntityResolver(entityResolver);
            SAXSource s = new SAXSource(xmlReader, SAXSource.sourceToInputSource(src));
            // parse through FOP
            Result res = new SAXResult(fop.getDefaultHandler());

            // Start the transformation and rendering process
            transformer.transform(s, res);

        } catch (SAXException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (ParserConfigurationException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        // Return the result
        sendPDF(out.toByteArray(), outFilename, response);
    }

    /** @return a new FOUserAgent for FOP */
    protected FOUserAgent getFOUserAgent() {
        FOUserAgent userAgent = fopFactory.newFOUserAgent();
        // Configure foUserAgent as desired
        return userAgent;
    }

}
