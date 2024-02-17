vcl 4.0;

##########################
## VLP

import directors;

backend vlp1 {
    .host = "zope";
    .port = "8080";
    /* .probe = {
        .url = "/";
        .interval = 30s;
        .timeout = 10s;
        .window = 5;
        .threshold = 3;
    } */
}

/*
backend vlp2 {
    .host = "zope2";
    .port = "8080";
}
*/

acl purge {
    "127.0.0.1";
    "zope";
#    "zope2";
}

sub vcl_init {
    new vlps = directors.round_robin();
    vlps.add_backend(vlp1);
#    vlps.add_backend(vlp2);
}

sub vcl_recv {
    // vlp
    set req.backend_hint = vlps.backend();

    /* filter actions */
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "PURGE" &&
        req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        /* POST - Logins and edits */
        if (req.method == "POST") {
            return(pass);
        }
        /* PURGE - The CacheFu product can invalidate updated URLs */
        if (req.method == "PURGE") {
            if (!client.ip ~ purge) {
                return (synth(405, "Not allowed."));
                //error 405 "Not allowed.";
            }
            return(purge);
        }
        return (pass);
    }

    /* don't cache authenticated requests */
    if (req.http.Authorization || req.http.Cookie && 
        req.http.Cookie ~ "__ac(_(name|password|persistent))=") {
        /* Force lookup of specific urls unlikely to need protection */
        if (req.url ~ "\.(js|css)") {
            unset req.http.cookie;
            return(hash);
        }
        return(pass);
    }

    return (hash);
}

sub vcl_hit {
    if (req.method == "PURGE") {
        return (synth(200, "Purged."));
        //error 200 "Purged.";
    }
    if (obj.ttl >= 0s) {
        // A pure unadultered hit, deliver it
        return (deliver);
    }
    if (obj.ttl + obj.grace > 0s) {
        // Object is in grace, deliver it
        // Automatically triggers a background fetch
        return (deliver);
    }
    // fetch & deliver once we get the result
    return (miss);
}

sub vcl_miss {
    if (req.method == "PURGE") {
        return (synth(404, "Not in cache."));
        //error 404 "Not in cache.";
    }
    // default logic:
    return (fetch);
}

sub vcl_backend_response {
    # hier wird eine min TTL von einer Stunde gesetzt.
    #changed to 10 hours. ROC: changed to 1h and omit server errors
    if (beresp.ttl < 3600s && beresp.status < 500) {
        set beresp.ttl = 3600s;
    }
}

