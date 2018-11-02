--
-- Name: i2b2_load_tree_full; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE i2b2_load_tree_full (
    idroot integer,
    idchild integer
);

--
-- Name: tm_wz_idx_child; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_child ON i2b2_load_tree_full USING btree (idchild, idroot);

--
-- Name: tm_wz_idx_root; Type: INDEX; Schema: tm_dataloader; Owner: -
--
CREATE INDEX tm_wz_idx_root ON i2b2_load_tree_full USING btree (idroot, idchild);

