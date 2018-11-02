--
-- Name: i2b2_load_path_with_count; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE i2b2_load_path_with_count (
    c_fullname character varying(2000) NOT NULL,
    nbr_children integer
);

--
-- Name: i2b2_load_path_with_count i2b2_load_path_with_count_pkey; Type: CONSTRAINT; Schema: tm_dataloader; Owner: -
--
ALTER TABLE ONLY i2b2_load_path_with_count
    ADD CONSTRAINT i2b2_load_path_with_count_pkey PRIMARY KEY (c_fullname);

--
-- Name: tm_wz_idx_path_count; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_path_count ON i2b2_load_path_with_count USING btree (c_fullname);

