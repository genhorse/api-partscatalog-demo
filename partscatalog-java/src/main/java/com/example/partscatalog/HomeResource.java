package com.example.partscatalog;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * Home page resource - serves landing page at root path.
 */
@RequestScoped
@Path("/")
public class HomeResource {

    @GET
    @Produces(MediaType.TEXT_HTML)
    public Response getHome() {
        try (InputStream is = getClass().getResourceAsStream("/web/index.html")) {
            if (is == null) {
                return Response.status(Response.Status.NOT_FOUND)
                        .entity("<html><body><h1>404: index.html not found</h1></body></html>")
                        .build();
            }
            String html = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            return Response.ok(html).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }
}
