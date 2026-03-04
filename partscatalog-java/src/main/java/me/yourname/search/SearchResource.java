package me.yourname.search;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.sql.DataSource;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * SearchResource acts as a thin proxy between the client and PostgreSQL.
 * It delegates all business logic to the database layer (PL/pgSQL).
 */
@Path("/search")
@RequestScoped
public class SearchResource {

    @Inject
    @Named("triadDS")
    private DataSource dataSource;

    /**
     * Serves the static HTML frontend from resources.
     * Path: /search/ui
     */
    @GET
    @Path("/ui")
    @Produces(MediaType.TEXT_HTML)
    public Response getFrontend() {
        try (InputStream is = getClass().getResourceAsStream("/web/index.html")) {
            if (is == null) {
                return Response.status(Response.Status.NOT_FOUND)
                        .entity("<html><body><h1>404: index.html not found in resources/web/</h1></body></html>")
                        .build();
            }
            String html = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            return Response.ok(html).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    /**
     * GET: Search parts using the triad-based optimized index.
     * @param q The search query string.
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response find(@QueryParam("q") String q) {
        return callDb("GET", q, null);
    }

    /**
     * POST: Create a new part or perform bulk insertion.
     * @param jsonBody JSON object or array of parts.
     */
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response create(String jsonBody) {
        return callDb("POST", null, jsonBody);
    }

    /**
     * DELETE: Remove a specific part by its ID.
     * @param id The part ID to delete.
     */
    @DELETE
    @Produces(MediaType.APPLICATION_JSON)
    public Response delete(@QueryParam("q") String id) {
        return callDb("DELETE", id, null);
    }

    /**
     * PUT: Update an existing part or perform bulk update.
     * @param jsonBody JSON object or array with updated data.
     */
    @PUT
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response update(String jsonBody) {
        return callDb("PUT", null, jsonBody);
    }

    /**
     * Universal database proxy method.
     * Calls the 'handle_request' PL/pgSQL function and returns the JSONB result.
     */
    private Response callDb(String method, String query, String payload) {
        String sql = "SELECT handle_request(?::text, ?::text, ?::jsonb)";
        
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, method);
            stmt.setString(2, query != null ? query : "");
            stmt.setString(3, payload != null ? payload : "{}");

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String result = rs.getString(1);
                    if (result == null) return Response.status(Response.Status.NOT_FOUND).build();
                    return Response.ok(result).build();
                }
            }
        } catch (Exception e) {
            // Simple JSON error formatting
            String errorMessage = e.getMessage().replace("\"", "'");
            return Response.serverError()
                    .entity("{\"status\":\"error\",\"message\":\"" + errorMessage + "\"}")
                    .build();
        }
        return Response.status(Response.Status.NOT_FOUND).build();
    }
}
