-- =====================================================================
-- REMEDI UTS - SCPMK0320703
-- Nama : Bilqis Audynova Prasanty | NIM : 264311063 | Kelas : 1C
-- Prodi: Teknologi Rekayasa Perangkat Lunak (TRPL)
-- Basis data : replika database ETLE kelompok + 1 tabel tambahan
-- ===================================================================== 

-- =====================================================================
-- PENAMBAHAN PROSES BISNIS
-- Setiap pelanggaran ETLE wajib disertai satu atau lebih foto bukti (foto kendaraan, foto plat nomor, foto situasi).

-- Aturan bisnis:
-- 1. Satu pelanggaran memiliki 1..N foto bukti.
-- 2. Foto bukti tidak dapat berdiri sendiri tanpa pelanggarannya (entitas lemah).
-- 3. Jika pelanggaran dihapus, foto buktinya ikut terhapus.
-- ===================================================================== 


-- =====================================================================
-- TAHAP 1 - PEMODELAN KONSEPTUAL (ERD)
   ---------------------------------------------------------------------
-- Entitas baru : BUKTI_FOTO (entitas LEMAH)
-- Pemilik      : PELANGGARAN (identifying owner)
-- Atribut      : urutan_foto (diskriminator/partial key), jenis_foto, nama_file, ukuran_kb, waktu_rekam
-- Relasi       : PELANGGARAN --(memiliki, identifying)--> BUKTI_FOTO
-- Kardinalitas : 1 : N (satu pelanggaran memiliki 1..N foto; satu foto milik tepat satu pelanggaran)
-- Partisipasi  : total di sisi BUKTI_FOTO

-- Relasi entitas lama (replika kelompok):
-- - PETUGAS     1 : N  PELANGGARAN
-- - KENDARAAN   1 : N  PELANGGARAN
-- - PELANGGARAN M : N  JENIS_PELANGGARAN (via PELANGGARAN_JENIS)
-- - KENDARAAN   spesialisasi -> RODA_2 / RODA_4

-- ERD teks:
-- [PETUGAS]--1:N--<menerbitkan>--[PELANGGARAN]--1:N--<memiliki>==[[BUKTI_FOTO]]
-- [KENDARAAN]--1:N--<terlibat>--[PELANGGARAN]
-- ([[ ]] dan == = entitas lemah dan relasi identifying)
-- ===================================================================== 


-- =====================================================================
-- TAHAP 2 - PEMODELAN LOGIS
   ---------------------------------------------------------------------
-- Skema relasional tabel baru:
-- BUKTI_FOTO (no_tilang PK/FK, urutan_foto PK, jenis_foto, nama_file, ukuran_kb, waktu_rekam)
-- FK: no_tilang -> PELANGGARAN(no_tilang)

-- ===================================================================== 

-- Normalisasi:
--
--   UNF : satu baris pelanggaran berisi banyak foto bukti sekaligus.
--     no_tilang | tanggal    | nrp_petugas | nama_petugas     | foto
--     TL-001    | 2026-03-04 | 80091312    | Septa Firmansyah | (1 Kendaraan: ae1270cr_depan.jpg), (2 Plat Nomor: ae1270cr_plat.jpg), (3 Situasi: ae1270cr_situasi.jpg)
--
--   1NF : satu baris = satu foto di satu pelanggaran. Kunci (no_tilang, urutan_foto).
--     no_tilang | urutan_foto | tanggal    | nrp_petugas | nama_petugas     | jenis_foto | nama_file
--     TL-001    | 1           | 2026-03-04 | 80091312    | Septa Firmansyah | Kendaraan  | ae1270cr_depan.jpg
--     TL-001    | 2           | 2026-03-04 | 80091312    | Septa Firmansyah | Plat Nomor | ae1270cr_plat.jpg
--     TL-001    | 3           | 2026-03-04 | 80091312    | Septa Firmansyah | Situasi    | ae1270cr_situasi.jpg
--
--   2NF : tanggal, nrp_petugas, nama_petugas hanya bergantung pada no_tilang
--         (sebagian kunci), jadi dipindah ke tabel PELANGGARAN.
--     BUKTI_FOTO (no_tilang, urutan_foto, jenis_foto, nama_file, ukuran_kb, waktu_rekam)
--
--   3NF : nama_petugas bergantung pada nrp_petugas, bukan langsung pada no_tilang
--         (transitif), jadi dipindah ke tabel PETUGAS. Hasil akhir: PETUGAS,
--         PELANGGARAN, BUKTI_FOTO (sesuai database kelompok + 1 tabel baru).



/* =====================================================================
   TAHAP 3 - PEMODELAN FISIK (DDL)
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS db_etle_remedi;
USE db_etle_remedi;

-- ---------------------------------------------------------------------
-- A. STRUKTUR BASIS DATA KELOMPOK (REPLIKA)
-- ---------------------------------------------------------------------

-- 1. TABEL
CREATE TABLE petugas (
  nrp           VARCHAR(20)  PRIMARY KEY,
  nama_petugas  VARCHAR(100) NOT NULL,
  pangkat       VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE kendaraan (
  nomor_polisi    VARCHAR(15) PRIMARY KEY,
  jenis_kendaraan VARCHAR(10) NOT NULL,
  merk            VARCHAR(50),
  nama_pemilik    VARCHAR(100),
  alamat_pemilik  VARCHAR(200),
  CONSTRAINT chk_jenis CHECK (jenis_kendaraan IN ('Roda 2','Roda 4'))
) ENGINE=InnoDB;

-- Spesialisasi kendaraan
CREATE TABLE roda_2 (
  nomor_polisi VARCHAR(15) PRIMARY KEY,
  kapasitas_cc INT,
  tipe_motor   VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE roda_4 (
  nomor_polisi VARCHAR(15) PRIMARY KEY,
  jumlah_sumbu INT,
  jbb_kg       INT
) ENGINE=InnoDB;

CREATE TABLE jenis_pelanggaran (
  kode_pasal    VARCHAR(10)  PRIMARY KEY,
  deskripsi     VARCHAR(200),
  denda_dasar   INT,
  berlaku_untuk VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE pelanggaran (
  no_tilang    VARCHAR(30) PRIMARY KEY,
  no_referensi VARCHAR(30),
  tanggal      DATE,
  nrp_petugas  VARCHAR(20),
  nomor_polisi VARCHAR(15)
) ENGINE=InnoDB;

CREATE TABLE pelanggaran_jenis (
  no_tilang  VARCHAR(30) NOT NULL,
  kode_pasal VARCHAR(10) NOT NULL,
  PRIMARY KEY (no_tilang, kode_pasal)
) ENGINE=InnoDB;

-- Tabel rekapitulasi (denormalisasi terkontrol)
CREATE TABLE rekap_pelanggaran_harian (
  tanggal     DATE        NOT NULL,
  kode_pasal  VARCHAR(10) NOT NULL,
  jumlah      INT         NOT NULL DEFAULT 0,
  total_denda BIGINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (tanggal, kode_pasal)
) ENGINE=InnoDB;

-- 2. INDEX
CREATE INDEX idx_kendaraan_nama_pemilik ON kendaraan(nama_pemilik);
CREATE INDEX idx_pelanggaran_tanggal    ON pelanggaran(tanggal);
CREATE INDEX idx_pelanggaran_nrp        ON pelanggaran(nrp_petugas);
CREATE INDEX idx_pelanggaran_nopol      ON pelanggaran(nomor_polisi);
CREATE INDEX idx_pj_kode_pasal          ON pelanggaran_jenis(kode_pasal);

-- 3. RELASI (FOREIGN KEY)
ALTER TABLE pelanggaran
  ADD CONSTRAINT fk_pelanggaran_petugas
  FOREIGN KEY (nrp_petugas) REFERENCES petugas(nrp)
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE pelanggaran
  ADD CONSTRAINT fk_pelanggaran_kendaraan
  FOREIGN KEY (nomor_polisi) REFERENCES kendaraan(nomor_polisi)
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE roda_2
  ADD CONSTRAINT fk_roda2_kendaraan
  FOREIGN KEY (nomor_polisi) REFERENCES kendaraan(nomor_polisi)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE roda_4
  ADD CONSTRAINT fk_roda4_kendaraan
  FOREIGN KEY (nomor_polisi) REFERENCES kendaraan(nomor_polisi)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE pelanggaran_jenis
  ADD CONSTRAINT fk_pj_pelanggaran
  FOREIGN KEY (no_tilang) REFERENCES pelanggaran(no_tilang)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE pelanggaran_jenis
  ADD CONSTRAINT fk_pj_jenis
  FOREIGN KEY (kode_pasal) REFERENCES jenis_pelanggaran(kode_pasal)
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE rekap_pelanggaran_harian
  ADD CONSTRAINT fk_rekap_pasal
  FOREIGN KEY (kode_pasal) REFERENCES jenis_pelanggaran(kode_pasal)
  ON DELETE RESTRICT ON UPDATE CASCADE;


-- ---------------------------------------------------------------------
-- B. TABEL TAMBAHAN REMEDI: bukti_foto (ENTITAS LEMAH)
-- ---------------------------------------------------------------------
CREATE TABLE bukti_foto (
  no_tilang    VARCHAR(30)  NOT NULL,
  urutan_foto  TINYINT      NOT NULL,
  jenis_foto   VARCHAR(20)  NOT NULL,
  nama_file    VARCHAR(150) NOT NULL,
  ukuran_kb    INT          NOT NULL,
  waktu_rekam  DATETIME     NOT NULL,
  PRIMARY KEY (no_tilang, urutan_foto),
  CONSTRAINT chk_urutan_foto CHECK (urutan_foto BETWEEN 1 AND 10),
  CONSTRAINT chk_jenis_foto  CHECK (jenis_foto IN ('Kendaraan','Plat Nomor','Situasi')),
  CONSTRAINT chk_ukuran_kb   CHECK (ukuran_kb > 0),
  CONSTRAINT uq_nama_file    UNIQUE (nama_file),
  CONSTRAINT fk_bukti_pelanggaran FOREIGN KEY (no_tilang)
    REFERENCES pelanggaran(no_tilang)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- C. INDEX TABEL TAMBAHAN
-- ---------------------------------------------------------------------
CREATE INDEX idx_bukti_waktu ON bukti_foto(waktu_rekam);
