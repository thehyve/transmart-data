--
-- Name: i2b2_load_path; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE i2b2_load_path (
    path character varying(700) NOT NULL,
    path50 character varying(50),
    path100 character varying(100),
    path150 character varying(150),
    path200 character varying(200),
    path_len integer,
    record_id integer
);

--
-- Name: i2b2_load_path i2b2_load_path_pkey; Type: CONSTRAINT; Schema: tm_dataloader; Owner: -
--
ALTER TABLE ONLY i2b2_load_path
    ADD CONSTRAINT i2b2_load_path_pkey PRIMARY KEY (path);

--
-- Name: tm_wz_idx_path; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path ON i2b2_load_path USING btree (path varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path100; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path100 ON i2b2_load_path USING btree (path100 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path150; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path150 ON i2b2_load_path USING btree (path150 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path200; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path200 ON i2b2_load_path USING btree (path200 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path50; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path50 ON i2b2_load_path USING btree (path50 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path_len; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path_len ON i2b2_load_path USING btree (path_len, path varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path_len100; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path_len100 ON i2b2_load_path USING btree (path_len, path100 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path_len150; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path_len150 ON i2b2_load_path USING btree (path_len, path150 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path_len200; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path_len200 ON i2b2_load_path USING btree (path_len, path200 varchar_pattern_ops, record_id);

--
-- Name: tm_wz_idx_path_len50; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path_len50 ON i2b2_load_path USING btree (path_len, path50 varchar_pattern_ops, record_id);

