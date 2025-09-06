
-- Seata Tables for Oracle
CREATE TABLE global_table (
    xid VARCHAR2(128) NOT NULL,
    transaction_id NUMBER(19) NOT NULL,
    status NUMBER(3) NOT NULL,
    application_id VARCHAR2(32),
    transaction_service_group VARCHAR2(32),
    transaction_name VARCHAR2(128),
    timeout NUMBER(10),
    begin_time NUMBER(19),
    application_data VARCHAR2(2000),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_global_table PRIMARY KEY (xid)
);

CREATE TABLE branch_table (
    branch_id NUMBER(19) NOT NULL,
    xid VARCHAR2(128) NOT NULL,
    transaction_id NUMBER(19),
    resource_group_id VARCHAR2(32),
    resource_id VARCHAR2(256),
    branch_type VARCHAR2(8),
    status NUMBER(3),
    client_id VARCHAR2(64),
    application_data VARCHAR2(2000),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_branch_table PRIMARY KEY (branch_id)
);

CREATE TABLE lock_table (
    row_key VARCHAR2(128) NOT NULL,
    xid VARCHAR2(128),
    transaction_id NUMBER(19),
    branch_id NUMBER(19) NOT NULL,
    resource_id VARCHAR2(256),
    table_name VARCHAR2(32),
    pk VARCHAR2(36),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_lock_table PRIMARY KEY (row_key)
);

CREATE TABLE undo_log (
    branch_id NUMBER(19) NOT NULL,
    xid VARCHAR2(128) NOT NULL,
    context VARCHAR2(128) NOT NULL,
    rollback_info BLOB NOT NULL,
    log_status NUMBER(10) NOT NULL,
    log_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_undo_log PRIMARY KEY (branch_id, xid)
);

INSERT INTO stock (id, product_id, total, residue) VALUES (1, 1, 1000, 1000);
INSERT INTO stock (id, product_id, total, residue) VALUES (2, 2, 500, 500);

COMMIT;

