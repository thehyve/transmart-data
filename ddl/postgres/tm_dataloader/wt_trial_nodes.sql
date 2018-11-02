--
-- Name: wt_trial_nodes; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE wt_trial_nodes (
    leaf_node character varying(4000),
    category_cd character varying(250),
    visit_name character varying(100),
    sample_type character varying(100),
    data_label character varying(500),
    node_name character varying(500),
    data_value character varying(500),
    data_type character varying(20),
    data_label_ctrl_vocab_code character varying(500),
    data_value_ctrl_vocab_code character varying(500),
    data_label_components character varying(1000),
    link_type character varying(50),
    obs_string character varying(100),
    valuetype_cd character varying(50),
    rec_num numeric,
    baseline_value character varying(250)
);

--
-- Name: idx_wt_trialnodes; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX idx_wt_trialnodes ON wt_trial_nodes USING btree (leaf_node, node_name);

--
-- Name: idx_wtn_load_clinical; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX idx_wtn_load_clinical ON wt_trial_nodes USING btree (leaf_node, category_cd, data_label);

