-- =====================================================
-- AUTOGESTÃO GARAGEM UNIFICADA - SUPABASE SCHEMA & SEED
-- Gerado automaticamente a partir do Google Sheets
-- =====================================================

-- 1. Limpeza (opcional, para recriação limpa)
drop table if exists cronograma cascade;
drop table if exists abastecimentos cascade;
drop table if exists manutencoes cascade;
drop table if exists veiculos cascade;

-- 2. Tabela de Veículos
create table veiculos (
    id text primary key,
    nome text not null,
    badge text,
    icon text,
    odometro integer not null default 0,
    spec_label text,
    updated_at timestamptz default now()
);

-- 3. Tabela de Manutenções (Histórico)
create table manutencoes (
    id text primary key,
    veiculo_id text not null references veiculos(id) on delete cascade,
    servico text not null,
    km integer not null,
    data date not null,
    valor numeric(10,2) not null default 0,
    categoria text not null default 'Manutenção',
    created_at timestamptz default now()
);
create index idx_manutencoes_veiculo_km on manutencoes(veiculo_id, km desc);

-- 4. Tabela de Abastecimentos
create table abastecimentos (
    id text primary key,
    veiculo_id text not null references veiculos(id) on delete cascade,
    data date not null,
    km integer not null,
    combustivel text not null,
    litros numeric(10,3) not null,
    valor numeric(10,2) not null,
    preco_litro numeric(10,3) not null,
    tanque_cheio boolean not null default true,
    km_rodados integer,
    km_l numeric(10,2),
    custo_km numeric(10,2),
    posto text,
    created_at timestamptz default now()
);
create index idx_abastecimentos_veiculo_km on abastecimentos(veiculo_id, km desc);

-- 5. Tabela de Cronograma Preventivo
create table cronograma (
    id text primary key,
    veiculo_id text not null references veiculos(id) on delete cascade,
    titulo text not null,
    target_km integer,
    target_date date,
    valor_estimado numeric(10,2) default 0,
    categoria text default 'Revisão',
    done boolean not null default false,
    created_at timestamptz default now()
);

-- 6. Segurança RLS (Row Level Security)
alter table veiculos enable row level security;
alter table manutencoes enable row level security;
alter table abastecimentos enable row level security;
alter table cronograma enable row level security;

create policy "Acesso publico veiculos" on veiculos for all using (true) with check (true);
create policy "Acesso publico manutencoes" on manutencoes for all using (true) with check (true);
create policy "Acesso publico abastecimentos" on abastecimentos for all using (true) with check (true);
create policy "Acesso publico cronograma" on cronograma for all using (true) with check (true);

-- 7. Habilitar Realtime para sincronização instantânea
alter publication supabase_realtime add table veiculos;
alter publication supabase_realtime add table manutencoes;
alter publication supabase_realtime add table abastecimentos;
alter publication supabase_realtime add table cronograma;

-- =====================================================
-- INSERÇÃO DE DADOS INICIAIS (SEED)
-- =====================================================

-- Veículos cadastrados
insert into veiculos (id, nome, badge, icon, odometro, spec_label) values
    ('voyage', 'VW Voyage 1.6 Highline', 'EA111 8V', 'fa-car', 104465, 'EA111 VHT 1.6 - VW 502.00 5W-40'),
    ('crosser', 'Yamaha XTZ 150 Crosser', '150cc BlueFlex', 'fa-motorcycle', 74781, 'Motor 150cc SOHC - Motul 5000+ 10W-40');

-- Manutenções do Voyage (85 registros)
insert into manutencoes (id, veiculo_id, servico, km, data, valor, categoria) values
('gs_voyage_2', 'voyage', 'CARRO', 70940, '2020-04-27', 29000, 'Manutenção'),
('gs_voyage_3', 'voyage', 'LÂMPADAS DA LANTERNA (RÉ)', 70980, '2020-05-04', 5.8, 'Manutenção'),
('gs_voyage_4', 'voyage', 'LIMPEZA DO TBI', 71000, '2020-05-08', 0, 'Manutenção'),
('gs_voyage_5', 'voyage', 'REGULAGEM DO GNV', 71200, '2020-06-05', 0, 'Manutenção'),
('gs_voyage_6', 'voyage', 'CALHA DE CHUVA', 71500, '2020-06-13', 103.8, 'Manutenção'),
('gs_voyage_7', 'voyage', 'FILTRO DE AR E LIMPEZA', 71550, '2020-06-16', 24, 'Manutenção'),
('gs_voyage_8', 'voyage', 'LANTERNA TRASEIRA DIREITA', 71700, '2020-07-02', 0, 'Manutenção'),
('gs_voyage_9', 'voyage', 'SUPORTE GPS', 71900, '2020-07-17', 30, 'Manutenção'),
('gs_voyage_10', 'voyage', 'BOTÃO ABRE/FECHA PORTAS', 71900, '2020-07-18', 0, 'Manutenção'),
('gs_voyage_11', 'voyage', 'Alto Falante JBL', 72000, '2020-07-25', 155, 'Manutenção'),
('gs_voyage_12', 'voyage', 'Antena Tubarão', 72250, '2020-08-12', 25, 'Manutenção'),
('gs_voyage_13', 'voyage', 'Limpadores de Parabrisa', 73305, '2020-11-10', 76, 'Manutenção'),
('gs_voyage_14', 'voyage', 'Extintor de incêndio', 73305, '2020-11-10', 45, 'Manutenção'),
('gs_voyage_15', 'voyage', 'Óleo + Filtro de óleo', 73305, '2020-11-10', 214, 'Manutenção'),
('gs_voyage_16', 'voyage', 'Calço do motor', 74000, '2020-12-21', 691, 'Manutenção'),
('gs_voyage_18', 'voyage', 'Bieletas', 75000, '2021-02-18', 110, 'Manutenção'),
('gs_voyage_19', 'voyage', 'LED lanternas dianteiras', 76000, '2021-05-01', 6, 'Manutenção'),
('gs_voyage_20', 'voyage', '2 Pneus Traseiros + Bicos', 77000, '2021-07-08', 632, 'Manutenção'),
('gs_voyage_21', 'voyage', 'Botões do vidro elétrico (LE + LD)', 78288, '2021-08-20', 65, 'Manutenção'),
('gs_voyage_22', 'voyage', 'Apoio de braço', 79000, '2021-11-20', 120, 'Manutenção'),
('gs_voyage_23', 'voyage', 'Moldura 2 Din', 79000, '2021-11-20', 120, 'Manutenção'),
('gs_voyage_24', 'voyage', 'Multimídia Positron SP8240', 79000, '2021-11-26', 450, 'Manutenção'),
('gs_voyage_25', 'voyage', 'Alternador', 79470, '2021-12-06', 350, 'Manutenção'),
('gs_voyage_26', 'voyage', 'Bobina de Ignição', 79470, '2021-12-06', 100, 'Manutenção'),
('gs_voyage_27', 'voyage', 'Cabo de Vela', 79470, '2021-12-06', 75, 'Manutenção'),
('gs_voyage_28', 'voyage', 'Velas', 79470, '2021-12-06', 145, 'Manutenção'),
('gs_voyage_29', 'voyage', 'Óleo', 79470, '2021-12-06', 147.6, 'Manutenção'),
('gs_voyage_30', 'voyage', 'Filtro de óleo', 79470, '2021-12-06', 16, 'Manutenção'),
('gs_voyage_31', 'voyage', 'Pastilha de freio', 79470, '2021-12-06', 80, 'Manutenção'),
('gs_voyage_32', 'voyage', 'Regulagem do freio de mão', 79470, '2021-12-06', 0, 'Manutenção'),
('gs_voyage_33', 'voyage', 'Fluido de freio', 79470, '2021-12-06', 35.8, 'Manutenção'),
('gs_voyage_34', 'voyage', 'Mão de obra', 79470, '2021-12-06', 300, 'Manutenção'),
('gs_voyage_35', 'voyage', 'Conserto da porta do motorista', 79490, '2021-12-11', 0, 'Manutenção'),
('gs_voyage_36', 'voyage', 'Polimento Cristalizado', 79490, '2021-12-11', 250, 'Manutenção'),
('gs_voyage_37', 'voyage', 'Filtro de ar + Higienização', 79750, '2021-12-20', 29, 'Manutenção'),
('gs_voyage_39', 'voyage', 'Bateria Power Free', 81400, '2022-05-07', 235.8, 'Manutenção'),
('gs_voyage_40', 'voyage', 'Correia do alternador + Correia do ar cond.', 81450, '2022-05-11', 96, 'Manutenção'),
('gs_voyage_41', 'voyage', 'Vazamento de óleo', 81450, '2022-05-11', 340, 'Manutenção'),
('gs_voyage_42', 'voyage', 'Borrachas do Anti-Chamas', 81450, '2022-05-11', 35, 'Manutenção'),
('gs_voyage_43', 'voyage', 'Óleo Lubrax Supra 5w40', 81450, '2022-05-11', 72, 'Manutenção'),
('gs_voyage_44', 'voyage', 'Válvula do cilindro do GNV', 82600, '2022-08-15', 250, 'Manutenção'),
('gs_voyage_45', 'voyage', 'Óleo Lubrax Valora 5w40 (502/505)', 83828, '2022-12-02', 180, 'Manutenção'),
('gs_voyage_46', 'voyage', 'Filtro de óleo Wega', 83828, '2022-12-02', 20, 'Manutenção'),
('gs_voyage_47', 'voyage', 'Fluido de freio', 84000, '2022-12-05', 85, 'Manutenção'),
('gs_voyage_48', 'voyage', 'Fluido da Direção Hidráulica', 84000, '2022-12-05', 85, 'Manutenção'),
('gs_voyage_49', 'voyage', 'Filtro de Ar', 84000, '2022-12-05', 24.5, 'Manutenção'),
('gs_voyage_50', 'voyage', 'Filtro de Combustível', 84000, '2022-12-05', 24, 'Manutenção'),
('gs_voyage_51', 'voyage', 'Alinhamento', 84000, '2022-12-05', 40, 'Manutenção'),
('gs_voyage_53', 'voyage', 'Sensor do Pedal da Embreagem', 87500, '2023-05-12', 79, 'Manutenção'),
('gs_voyage_54', 'voyage', 'Pneus Dianteiros', 90056, '2023-11-03', 527, 'Manutenção'),
('gs_voyage_55', 'voyage', 'Alinhamento + Balanceamento', 90056, '2023-11-03', 80, 'Manutenção'),
('gs_voyage_56', 'voyage', 'Kit dos Amortecedores', 90100, '2023-11-04', 245, 'Manutenção'),
('gs_voyage_57', 'voyage', 'Molas Traseiras GNV', 90100, '2023-11-04', 215, 'Manutenção'),
('gs_voyage_58', 'voyage', 'Mão de obra', 90100, '2023-11-04', 250, 'Manutenção'),
('gs_voyage_59', 'voyage', 'Óleo', 90730, '2023-12-04', 180, 'Manutenção'),
('gs_voyage_60', 'voyage', 'Filtro de Óleo', 90730, '2023-12-04', 20, 'Manutenção'),
('gs_voyage_61', 'voyage', 'Mão de obra', 90730, '2023-12-04', 10, 'Manutenção'),
('gs_voyage_62', 'voyage', 'Borracha das Portas', 90900, '2023-12-06', 220, 'Manutenção'),
('gs_voyage_63', 'voyage', 'Bobina de Ignição', 91580, '2023-12-15', 150, 'Manutenção'),
('gs_voyage_65', 'voyage', 'Limpador de Parabrisas', 94350, '2024-07-30', 35, 'Manutenção'),
('gs_voyage_66', 'voyage', 'Aditivo do Radiador', 95375, '2024-10-05', 45, 'Manutenção'),
('gs_voyage_67', 'voyage', 'Fluido de freio', 96367, '2024-12-27', 35, 'Manutenção'),
('gs_voyage_68', 'voyage', 'Óleo', 96368, '2024-12-30', 168, 'Manutenção'),
('gs_voyage_69', 'voyage', 'Filtro de óleo', 96368, '2024-12-30', 30, 'Manutenção'),
('gs_voyage_72', 'voyage', 'Carga de gás no arcond.', 96500, '2025-01-02', 0, 'Manutenção'),
('gs_voyage_73', 'voyage', 'Filtro do arcond.', 97000, '2025-01-17', 15, 'Manutenção'),
('gs_voyage_74', 'voyage', 'OrbiAir', 97000, '2025-01-17', 15, 'Manutenção'),
('gs_voyage_75', 'voyage', 'Limpeza do TBI', 99150, '2025-07-23', 0, 'Manutenção'),
('gs_voyage_76', 'voyage', 'Sensor de Sonda Lambda do GNV', 99150, '2025-07-23', 150, 'Manutenção'),
('gs_voyage_77', 'voyage', 'Filtro de ar do motor', 99170, '2025-07-24', 18.5, 'Manutenção'),
('gs_voyage_78', 'voyage', 'Calotas', 100201, '2025-10-26', 79, 'Manutenção'),
('gs_voyage_79', 'voyage', 'Troca do óleo e filtro', 100600, '2025-12-05', 218, 'Manutenção'),
('gs_voyage_80', 'voyage', 'Troca do óleo da caixa de marcha', 100600, '2025-12-05', 70, 'Manutenção'),
('gs_voyage_85', 'voyage', 'Embreagem', 101500, '2026-01-17', 850, 'Manutenção'),
('gs_voyage_86', 'voyage', 'Bateria', 101942, '2026-01-31', 300, 'Manutenção'),
('gs_voyage_87', 'voyage', 'Cabo e Sensor do ABS', 102400, '2026-04-01', 121, 'Manutenção'),
('gs_voyage_88', 'voyage', 'Alinhamento e Suspensão dianterira', 102470, '2026-04-06', 1710, 'Manutenção'),
('gs_voyage_89', 'voyage', 'Filtro de ar da cabine', 102775, '2026-05-16', 15, 'Manutenção'),
('gs_voyage_90', 'voyage', 'Vela e Cabo de vela', 104000, '2026-09-07', 169, 'Manutenção'),
('gs_voyage_91', 'voyage', 'Bobina de ignição', 104500, '2026-10-03', 160, 'Manutenção'),
('gs_voyage_100', 'voyage', 'Tampa do óleo do motor', 104345, '2026-10-31', 36, 'Manutenção'),
('gs_voyage_101', 'voyage', 'Correia alternador', 104400, '2026-11-03', 58, 'Manutenção'),
('gs_voyage_102', 'voyage', 'Kit Correia Dentada + Tensor (Urgência por tempo >5 anos)', 104500, '2026-11-04', 380, 'Manutenção'),
('gs_voyage_103', 'voyage', 'Filtro de Combustível', 104400, '2026-11-09', 45, 'Manutenção'),
('gs_voyage_104', 'voyage', 'Aditivo Etanol', 104465, '2026-11-14', 29, 'Manutenção');

-- Manutenções da Crosser (95 registros)
insert into manutencoes (id, veiculo_id, servico, km, data, valor, categoria) values
('gs_crosser_2', 'crosser', 'Vela de Ignição', 10200, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_3', 'crosser', 'FILTRO DE AR', 10200, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_4', 'crosser', 'FILTRO DO ÓLEO', 10200, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_5', 'crosser', 'O''RING DO FILTRO', 10200, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_6', 'crosser', 'ÓLEO', 10200, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_8', 'crosser', 'ÓLEO', 12500, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_9', 'crosser', 'ÓLEO', 15650, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_10', 'crosser', 'AJUSTE DA RELAÇÃO', 15650, '2026-01-01', 0, 'Manutenção'),
('gs_crosser_12', 'crosser', 'ÓLEO', 17300, '2020-02-03', 0, 'Manutenção'),
('gs_crosser_13', 'crosser', 'FILTRO DE COMB.', 17300, '2020-02-03', 0, 'Manutenção'),
('gs_crosser_14', 'crosser', 'RELAÇÃO', 17300, '2020-02-03', 0, 'Manutenção'),
('gs_crosser_15', 'crosser', 'FREIO TRASEIRO', 17300, '2020-02-03', 0, 'Manutenção'),
('gs_crosser_16', 'crosser', 'Vela de Ignição', 23000, '2020-06-14', 0, 'Manutenção'),
('gs_crosser_17', 'crosser', 'FILTRO DE AR', 23000, '2020-06-14', 0, 'Manutenção'),
('gs_crosser_18', 'crosser', 'FILTRO DO ÓLEO', 23000, '2020-06-14', 0, 'Manutenção'),
('gs_crosser_19', 'crosser', 'O''RING DO FILTRO', 23000, '2020-06-14', 0, 'Manutenção'),
('gs_crosser_20', 'crosser', 'ÓLEO', 23000, '2020-06-14', 0, 'Manutenção'),
('gs_crosser_21', 'crosser', 'ARRUELA BUJÃO', 23000, '2020-06-14', 0, 'Manutenção'),
('gs_crosser_22', 'crosser', 'ÓLEO', 24900, '2020-08-11', 0, 'Manutenção'),
('gs_crosser_23', 'crosser', 'ÓLEO', 26800, '2020-12-10', 0, 'Manutenção'),
('gs_crosser_25', 'crosser', 'PNEUS', 34600, '2021-07-10', 0, 'Manutenção'),
('gs_crosser_26', 'crosser', 'RELAÇÃO', 34600, '2021-07-10', 0, 'Manutenção'),
('gs_crosser_27', 'crosser', 'FREIO TRASEIRO', 34600, '2021-07-10', 0, 'Manutenção'),
('gs_crosser_28', 'crosser', 'COMPRA DA MOTO', 34750, '2021-07-19', 10500, 'Manutenção'),
('gs_crosser_29', 'crosser', 'Vela de Ignição', 35096, '2021-08-04', 50, 'Manutenção'),
('gs_crosser_30', 'crosser', 'RETROVISOR', 35260, '2021-08-18', 59.3, 'Manutenção'),
('gs_crosser_31', 'crosser', 'PNEUS', 35300, '2021-08-20', 606, 'Manutenção'),
('gs_crosser_32', 'crosser', 'FILTRO DE AR', 35400, '2021-08-26', 20, 'Manutenção'),
('gs_crosser_33', 'crosser', 'FILTRO DE COMB.', 35453, '2021-08-29', 12, 'Manutenção'),
('gs_crosser_34', 'crosser', 'ÓLEO', 35500, '2021-08-29', 20, 'Manutenção'),
('gs_crosser_36', 'crosser', 'ÓLEO', 37000, '2022-01-12', 45, 'Manutenção'),
('gs_crosser_37', 'crosser', 'FILTRO DO ÓLEO', 37000, '2022-01-12', 13, 'Manutenção'),
('gs_crosser_38', 'crosser', 'MÃO DE OBRA', 37000, '2022-01-12', 10, 'Manutenção'),
('gs_crosser_39', 'crosser', 'BUZINA', 38000, '2022-04-20', 12, 'Manutenção'),
('gs_crosser_40', 'crosser', 'CAPA TÉRMICA', 38000, '2022-04-20', 25, 'Manutenção'),
('gs_crosser_41', 'crosser', 'CAVALETE CENTRAL', 39043, '2022-06-17', 197.5, 'Manutenção'),
('gs_crosser_42', 'crosser', 'ÓLEO', 39043, '2022-06-17', 44, 'Manutenção'),
('gs_crosser_43', 'crosser', 'FILTRO DO ÓLEO', 39043, '2022-06-17', 12, 'Manutenção'),
('gs_crosser_44', 'crosser', 'CÂMARA DE AR', 41000, '2022-10-06', 80, 'Manutenção'),
('gs_crosser_45', 'crosser', 'ÓLEO', 41389, '2022-10-27', 50, 'Manutenção'),
('gs_crosser_46', 'crosser', 'FILTRO DO ÓLEO', 41389, '2022-10-27', 15, 'Manutenção'),
('gs_crosser_47', 'crosser', 'ORING DA VARETA', 41389, '2022-10-27', 2, 'Manutenção'),
('gs_crosser_49', 'crosser', 'Caixa de direção', 42233, '2023-01-02', 40, 'Manutenção'),
('gs_crosser_50', 'crosser', 'Retentores do garfo', 42233, '2023-01-02', 115, 'Manutenção'),
('gs_crosser_51', 'crosser', 'MÃO DE OBRA', 42233, '2023-01-02', 200, 'Manutenção'),
('gs_crosser_52', 'crosser', 'ÓLEO', 43460, '2023-03-10', 45, 'Manutenção'),
('gs_crosser_53', 'crosser', 'FILTRO DO ÓLEO', 43460, '2023-03-10', 12, 'Manutenção'),
('gs_crosser_54', 'crosser', 'ÓLEO', 45475, '2023-07-01', 45, 'Manutenção'),
('gs_crosser_55', 'crosser', 'FILTRO DO ÓLEO', 45475, '2023-07-01', 10, 'Manutenção'),
('gs_crosser_56', 'crosser', 'ALARME POSITRON', 45600, '2023-07-16', 281, 'Manutenção'),
('gs_crosser_57', 'crosser', 'BATERIA', 45800, '2023-07-21', 135, 'Manutenção'),
('gs_crosser_58', 'crosser', 'ÓLEO', 47478, '2023-10-15', 40, 'Manutenção'),
('gs_crosser_59', 'crosser', 'Caixa de direção', 47640, '2023-10-21', 140, 'Manutenção'),
('gs_crosser_60', 'crosser', 'RELAÇÃO', 48490, '2023-12-30', 115, 'Manutenção'),
('gs_crosser_61', 'crosser', 'Fuido de Freio', 48490, '2023-12-30', 23, 'Manutenção'),
('gs_crosser_62', 'crosser', 'Capa dpo Banco', 48490, '2023-12-30', 38, 'Manutenção'),
('gs_crosser_64', 'crosser', 'Lâmpada do Farol', 48600, '2024-01-03', 24, 'Manutenção'),
('gs_crosser_65', 'crosser', 'Óleo', 49338, '2024-02-13', 40, 'Manutenção'),
('gs_crosser_66', 'crosser', 'FILTRO DO ÓLEO', 49338, '2024-02-13', 11, 'Manutenção'),
('gs_crosser_67', 'crosser', 'Filtro de Ar', 50260, '2024-03-30', 22, 'Manutenção'),
('gs_crosser_68', 'crosser', 'FILTRO DE COMB.', 50260, '2024-03-30', 13, 'Manutenção'),
('gs_crosser_69', 'crosser', 'Óleo', 51420, '2024-06-01', 39, 'Manutenção'),
('gs_crosser_70', 'crosser', 'Vela de Ignição', 51870, '2024-06-30', 30, 'Manutenção'),
('gs_crosser_71', 'crosser', 'Óleo', 53342, '2024-08-31', 40, 'Manutenção'),
('gs_crosser_72', 'crosser', 'FILTRO DO ÓLEO', 53342, '2024-08-31', 9, 'Manutenção'),
('gs_crosser_73', 'crosser', 'Pastilha de freio', 53600, '2024-09-16', 35, 'Manutenção'),
('gs_crosser_74', 'crosser', 'Patim de freio', 53600, '2024-09-16', 28, 'Manutenção'),
('gs_crosser_75', 'crosser', 'Mão de obra', 53600, '2024-09-16', 35, 'Manutenção'),
('gs_crosser_77', 'crosser', 'Óleo', 55400, '2025-01-06', 39, 'Manutenção'),
('gs_crosser_78', 'crosser', 'Filtro de óleo', 55400, '2025-01-06', 10, 'Manutenção'),
('gs_crosser_79', 'crosser', 'Óleo', 57383, '2025-03-18', 39, 'Manutenção'),
('gs_crosser_80', 'crosser', 'Filtro de óleo', 57383, '2025-03-18', 13, 'Manutenção'),
('gs_crosser_81', 'crosser', 'Óleo', 59500, '2025-05-23', 39, 'Manutenção'),
('gs_crosser_82', 'crosser', 'Filtro de óleo', 59500, '2025-05-23', 16, 'Manutenção'),
('gs_crosser_83', 'crosser', 'Pneu Traseiro', 60300, '2025-06-16', 260, 'Manutenção'),
('gs_crosser_84', 'crosser', 'Vela de Ignição', 61050, '2025-07-07', 30, 'Manutenção'),
('gs_crosser_85', 'crosser', 'Filtro de ar do motor', 61050, '2025-07-07', 25, 'Manutenção'),
('gs_crosser_86', 'crosser', 'Óleo', 61575, '2025-07-19', 39, 'Manutenção'),
('gs_crosser_87', 'crosser', 'Óleo', 63440, '2025-09-29', 39, 'Manutenção'),
('gs_crosser_88', 'crosser', 'Filtro de óleo', 63440, '2025-09-29', 17, 'Manutenção'),
('gs_crosser_89', 'crosser', 'Pneu Dianteiro', 65100, '2025-11-13', 200, 'Manutenção'),
('gs_crosser_90', 'crosser', 'Óleo', 65530, '2025-11-30', 39, 'Manutenção'),
('gs_crosser_91', 'crosser', 'Filtro de óleo', 65530, '2025-11-30', 16, 'Manutenção'),
('gs_crosser_93', 'crosser', 'Relação', 66250, '2026-01-08', 120, 'Manutenção'),
('gs_crosser_94', 'crosser', 'Esticador da corrente', 66250, '2026-01-08', 15, 'Manutenção'),
('gs_crosser_99', 'crosser', 'Troca de Óleo e Filtro de Óleo', 72450, '2026-09-07', 57, 'Manutenção'),
('gs_crosser_100', 'crosser', 'Vela de ignição', 69675, '2026-06-06', 75, 'Manutenção'),
('gs_crosser_101', 'crosser', 'Pneu traseiro Maggion Viper', 65100, '2025-11-13', 220, 'Manutenção'),
('gs_crosser_102', 'crosser', 'Filtro de ar do motor', 67400, '2026-03-03', 35, 'Manutenção'),
('gs_crosser_103', 'crosser', 'Filtro de combustível', 67400, '2026-03-03', 20, 'Manutenção'),
('gs_crosser_104', 'crosser', 'Kit de transmissão', 66250, '2026-01-08', 135, 'Manutenção'),
('gs_crosser_105', 'crosser', 'Pastilha de Freio', 53600, '2024-09-16', 98, 'Manutenção'),
('gs_crosser_108', 'crosser', 'Inspeção e Troca de Pastilhas e Patim de Freio', 73000, '2026-11-02', 95, 'Manutenção'),
('gs_crosser_109', 'crosser', 'Óleo do Motor (Motul 5000+ 10W-40)', 74644, '2026-11-11', 47, 'Manutenção'),
('gs_crosser_110', 'crosser', 'Óleo do Motor (Motul 5000+ 10W-40)', 74644, '2026-11-11', 47, 'Manutenção');

-- Abastecimentos do Voyage (2 registros)
insert into abastecimentos (id, veiculo_id, data, km, combustivel, litros, valor, preco_litro, tanque_cheio, km_rodados, km_l, custo_km, posto) values
('fuel_voyage_1794316477947', 'voyage', '2026-11-09', 104420, 'Gasolina Comum', 16, 80, 5, false, null, null, null, 'Shell'),
('fuel_voyage_1794923413862', 'voyage', '2026-11-14', 104465, 'Etanol', 35.85, 178.87, 4.989, true, null, null, null, 'Shell');

-- Abastecimentos da Crosser (6 registros)
insert into abastecimentos (id, veiculo_id, data, km, combustivel, litros, valor, preco_litro, tanque_cheio, km_rodados, km_l, custo_km, posto) values
('fuel_crosser_1793411555229', 'crosser', '2026-10-17', 73826, 'Gasolina Aditivada', 7.42, 48.9, 6.59, true, null, null, null, 'Shell'),
('fuel_crosser_1793411610030', 'crosser', '2026-10-06', 73502, 'Gasolina Comum', 7.94, 52.32, 6.589, true, null, null, null, 'Shell'),
('fuel_crosser_1793411696797', 'crosser', '2026-09-27', 73146, 'Gasolina Comum', 6.88, 44.65, 6.49, true, null, null, null, 'Shell'),
('fuel_crosser_1793909692103', 'crosser', '2026-11-05', 74488, 'Gasolina Comum', 6.93, 44.98, 6.491, true, null, null, null, 'Shell'),
('fuel_crosser_1793909797340', 'crosser', '2026-10-27', 74180, 'Gasolina Comum', 7.47, 45.35, 6.071, true, null, null, null, 'Shell'),
('fuel_crosser_1794923221234', 'crosser', '2026-11-16', 74781, 'Gasolina Comum', 7.05, 45.75, 6.489, true, null, null, null, 'Shell');

-- Cronograma preventivo padrão
insert into cronograma (id, veiculo_id, titulo, target_km, target_date, valor_estimado, categoria, done) values
    ('plan_voyage_1001', 'voyage', 'Kit Correia Dentada + Tensor (Urgência por tempo >5 anos)', 104500, '2026-11-15', 380, 'Correias / Tensor', false),
    ('plan_voyage_1002', 'voyage', 'Filtro de Combustível (4 anos de uso)', 104500, '2026-11-20', 45, 'Filtros', false),
    ('plan_voyage_1003', 'voyage', 'Revisão 105k: Óleo 5W-40, Freio DOT 4 e Direção Hidráulica', 105000, '2026-12-10', 390, 'Motor / Óleo', false),
    ('plan_voyage_1004', 'voyage', 'Filtro de Ar do Motor e Cabine', 110000, '2027-06-15', 65, 'Filtros', false),
    ('plan_voyage_1005', 'voyage', 'Revisão 115k: Óleo 5W-40 + Filtro de Óleo', 115000, '2027-12-10', 220, 'Motor / Óleo', false),
    ('plan_voyage_1006', 'voyage', 'Revisão 120k: Velas, Cabos, Freios e Alinhamento', 120000, '2028-10-20', 480, 'Ignição / Elétrica', false),
    ('plan_crosser_2001', 'crosser', 'Inspeção e Troca de Pastilhas e Patim de Freio', 73000, '2026-11-10', 95, 'Freios', false),
    ('plan_crosser_2002', 'crosser', 'Troca de Óleo Motul 5000+ 10W-40 + Filtro de Óleo (75.000 km)', 75000, '2026-12-15', 57, 'Motor / Óleo', false),
    ('plan_crosser_2003', 'crosser', 'Troca de Óleo Motul 5000+ 10W-40 (77.500 km)', 77500, '2027-04-10', 45, 'Motor / Óleo', false),
    ('plan_crosser_2004', 'crosser', 'Revisão 80k: Óleo, Filtro de Ar, Vela NGK e Lubrificação Relação', 80000, '2027-08-20', 160, 'Motor / Óleo', false),
    ('plan_crosser_2005', 'crosser', 'Kit Relação (Coroa, Pinhão e Corrente c/ Retentor)', 84000, '2027-12-15', 165, 'Transmissão / Relação', false);

