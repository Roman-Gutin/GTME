USE ROLE AGENTS_SERVICE_ROLE;
USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE AGENTS_DEMO_WH;

CREATE OR REPLACE PROCEDURE MANAGE_FINDALL_RUN(ACTION VARCHAR, FINDALL_ID VARCHAR, PAYLOAD VARCHAR)
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
var payload = JSON.parse(PAYLOAD || '{}');
var result = {};
var stmt, rs, binds;

if (ACTION === 'log') {
    binds = [FINDALL_ID, payload.objective, payload.entity_type, JSON.stringify(payload.match_conditions), payload.generator, payload.match_limit];
    stmt = snowflake.createStatement({
        sqlText: "INSERT INTO FINDALL_RUNS (FINDALL_ID, OBJECTIVE, ENTITY_TYPE, MATCH_CONDITIONS, GENERATOR, MATCH_LIMIT, STATUS, IS_ACTIVE) SELECT ?, ?, ?, PARSE_JSON(?), ?, ?, 'created', TRUE",
        binds: binds
    });
    stmt.execute();
    result = {success: true, action: 'logged', findall_id: FINDALL_ID};
}
else if (ACTION === 'update_status') {
    binds = [payload.status, payload.is_active, payload.matched_count, FINDALL_ID];
    stmt = snowflake.createStatement({
        sqlText: "UPDATE FINDALL_RUNS SET STATUS = ?, IS_ACTIVE = ?, MATCHED_COUNT = ?, UPDATED_AT = CURRENT_TIMESTAMP() WHERE FINDALL_ID = ?",
        binds: binds
    });
    stmt.execute();
    result = {success: true, action: 'status_updated', findall_id: FINDALL_ID};
}
else if (ACTION === 'save_results') {
    binds = [JSON.stringify(payload.results), FINDALL_ID];
    stmt = snowflake.createStatement({
        sqlText: "UPDATE FINDALL_RUNS SET RESULTS = PARSE_JSON(?), UPDATED_AT = CURRENT_TIMESTAMP() WHERE FINDALL_ID = ?",
        binds: binds
    });
    stmt.execute();
    result = {success: true, action: 'results_saved', findall_id: FINDALL_ID};
}
else if (ACTION === 'save_enrichments') {
    binds = [JSON.stringify(payload.enrichments), FINDALL_ID];
    stmt = snowflake.createStatement({
        sqlText: "UPDATE FINDALL_RUNS SET ENRICHMENTS = PARSE_JSON(?), UPDATED_AT = CURRENT_TIMESTAMP() WHERE FINDALL_ID = ?",
        binds: binds
    });
    stmt.execute();
    result = {success: true, action: 'enrichments_saved', findall_id: FINDALL_ID};
}
else if (ACTION === 'get_details') {
    stmt = snowflake.createStatement({
        sqlText: "SELECT * FROM FINDALL_RUNS WHERE FINDALL_ID = ?",
        binds: [FINDALL_ID]
    });
    rs = stmt.execute();
    if (rs.next()) {
        result = {
            success: true,
            findall_id: rs.getColumnValue('FINDALL_ID'),
            objective: rs.getColumnValue('OBJECTIVE'),
            entity_type: rs.getColumnValue('ENTITY_TYPE'),
            match_conditions: rs.getColumnValue('MATCH_CONDITIONS'),
            generator: rs.getColumnValue('GENERATOR'),
            match_limit: rs.getColumnValue('MATCH_LIMIT'),
            status: rs.getColumnValue('STATUS'),
            is_active: rs.getColumnValue('IS_ACTIVE'),
            matched_count: rs.getColumnValue('MATCHED_COUNT'),
            results: rs.getColumnValue('RESULTS'),
            enrichments: rs.getColumnValue('ENRICHMENTS'),
            created_at: rs.getColumnValue('CREATED_AT'),
            created_by: rs.getColumnValue('CREATED_BY')
        };
    } else {
        result = {success: false, error: 'FindAll run not found'};
    }
}
else if (ACTION === 'get_recent') {
    var limit = payload.limit || 10;
    stmt = snowflake.createStatement({
        sqlText: "SELECT FINDALL_ID, OBJECTIVE, ENTITY_TYPE, STATUS, MATCHED_COUNT, CREATED_AT FROM FINDALL_RUNS ORDER BY CREATED_AT DESC LIMIT " + limit
    });
    rs = stmt.execute();
    var runs = [];
    while (rs.next()) {
        runs.push({
            findall_id: rs.getColumnValue('FINDALL_ID'),
            objective: rs.getColumnValue('OBJECTIVE'),
            entity_type: rs.getColumnValue('ENTITY_TYPE'),
            status: rs.getColumnValue('STATUS'),
            matched_count: rs.getColumnValue('MATCHED_COUNT'),
            created_at: rs.getColumnValue('CREATED_AT')
        });
    }
    result = {success: true, runs: runs};
}
else {
    result = {success: false, error: 'Unknown action: ' + ACTION};
}

return result;
$$;

