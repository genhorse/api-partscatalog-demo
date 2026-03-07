package com.example.partscatalog;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@RequestScoped
@Path("/")
public class OpenApiResource {

    @GET
    @Path("/swagger-ui")
    @Produces(MediaType.TEXT_HTML)
    public Response getSwaggerUi() {
        try (InputStream is = getClass().getResourceAsStream("/web/swagger-ui.html")) {
            if (is == null) {
                return Response.status(Response.Status.NOT_FOUND)
                        .entity("Swagger UI not found")
                        .build();
            }
            String html = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            return Response.ok(html).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }
}
