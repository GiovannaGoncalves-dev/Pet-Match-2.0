-- ============================================================================
-- PetMatch - Script do Banco de Dados (Versão alinhada ao Método TOPSIS)
-- Baseado em PetMatch2.0.sql + critérios quantitativos (1 a 5) e pesos (W)
-- Compatível com MySQL 8.0 e MySQL Workbench (Reverse Engineer)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS PetMatch
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE PetMatch;

-- ----------------------------------------------------------------------------
-- 1. Protetores, ONGs e Empresas (Quem cadastra os pets)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS anunciantes (
  id_anunciante INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  tipo_perfil VARCHAR(30) NOT NULL,          -- 'ONG', 'Protetor' ou 'Empresa'
  email VARCHAR(100) NOT NULL UNIQUE,
  senha VARCHAR(255) NOT NULL,
  telefone_whatsapp VARCHAR(20) NOT NULL,
  cidade VARCHAR(80) NOT NULL,
  chave_pix VARCHAR(100),
  rede_social VARCHAR(100)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Adotantes (Quem busca adotar)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS adotantes (
  id_adotante INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  senha VARCHAR(255) NOT NULL,
  telefone VARCHAR(20) NOT NULL,
  cidade VARCHAR(80) NOT NULL,
  tipo_preferido VARCHAR(50)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. Perfil de Preferências do Adotante (Restrições + Vetor de Pesos W - TOPSIS)
--    Relação 1:1 com adotantes (preenchida em questionario-perfil.jsp)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS perfil_preferencias (
  id_preferencia INT PRIMARY KEY AUTO_INCREMENT,
  id_adotante INT NOT NULL UNIQUE,

  -- Restrições / filtros eliminatórios do adotante
  especie_preferida VARCHAR(50),             -- 'Cachorro', 'Gato' ou NULL (qualquer)
  tipo_moradia VARCHAR(50) NOT NULL,         -- 'Apartamento', 'Casa sem quintal', 'Casa com quintal'
  possui_outros_animais BOOLEAN NOT NULL DEFAULT FALSE,
  possui_criancas BOOLEAN NOT NULL DEFAULT FALSE,
  aceita_necessidades_especiais BOOLEAN NOT NULL DEFAULT TRUE,

  -- Preferência alvo do adotante (escala 1 a 5) para critérios contextuais
  preferencia_porte TINYINT NOT NULL DEFAULT 3,        -- 1=Mini/Pequeno .. 5=Grande/Gigante
  preferencia_energia TINYINT NOT NULL DEFAULT 3,      -- 1=Muito calmo .. 5=Muito agitado

  -- Vetor de Pesos (W) do Método TOPSIS (importância atribuída pelo tutor: 0.00 a 1.00)
  peso_porte DECIMAL(4,2) NOT NULL DEFAULT 0.20,
  peso_energia DECIMAL(4,2) NOT NULL DEFAULT 0.20,
  peso_sociabilidade DECIMAL(4,2) NOT NULL DEFAULT 0.20,
  peso_independencia DECIMAL(4,2) NOT NULL DEFAULT 0.15,
  peso_custo DECIMAL(4,2) NOT NULL DEFAULT 0.15,
  peso_saude DECIMAL(4,2) NOT NULL DEFAULT 0.10,

  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_preferencias_adotante
    FOREIGN KEY (id_adotante) REFERENCES adotantes(id_adotante)
    ON DELETE CASCADE,
  CONSTRAINT chk_pref_porte CHECK (preferencia_porte BETWEEN 1 AND 5),
  CONSTRAINT chk_pref_energia CHECK (preferencia_energia BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. Pets (Dados descritivos, saúde, status + atributos quantitativos TOPSIS)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pets (
  id_pet INT PRIMARY KEY AUTO_INCREMENT,
  id_anunciante INT NOT NULL,
  nome VARCHAR(100) NOT NULL,
  especie VARCHAR(50) NOT NULL,              -- Cachorro, Gato, etc.
  porte VARCHAR(20) NOT NULL,                -- Pequeno, Médio, Grande
  sexo VARCHAR(10) NOT NULL,                 -- Macho, Fêmea
  idade VARCHAR(30),                         -- Ex: '2 anos', 'Filhote'
  temperamento VARCHAR(100),                 -- Ex: 'Dócil, calmo'
  cidade VARCHAR(80) NOT NULL,
  foto_url VARCHAR(255),
  historia_resgate TEXT,
  vacinado BOOLEAN NOT NULL DEFAULT FALSE,
  castrado BOOLEAN NOT NULL DEFAULT FALSE,
  vermifugado BOOLEAN NOT NULL DEFAULT FALSE,
  necessidades_especiais VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'Disponível', -- 'Disponível', 'Em Análise', 'Adotado'

  -- Atributos quantitativos (escala 1 a 5) usados na matriz de decisão do TOPSIS
  escala_porte TINYINT NOT NULL DEFAULT 3,            -- 1=Muito pequeno .. 5=Grande/Gigante
  nivel_energia TINYINT NOT NULL DEFAULT 3,           -- 1=Muito calmo .. 5=Muito agitado
  sociabilidade TINYINT NOT NULL DEFAULT 3,           -- 1=Reservado .. 5=Muito sociável (crianças/pets)
  independencia TINYINT NOT NULL DEFAULT 3,           -- 1=Dependente de companhia .. 5=Independente
  custo_manutencao TINYINT NOT NULL DEFAULT 3,        -- 1=Baixo custo .. 5=Alto custo (critério de custo)

  CONSTRAINT fk_pets_anunciante
    FOREIGN KEY (id_anunciante) REFERENCES anunciantes(id_anunciante)
    ON DELETE CASCADE,
  CONSTRAINT chk_pet_porte CHECK (escala_porte BETWEEN 1 AND 5),
  CONSTRAINT chk_pet_energia CHECK (nivel_energia BETWEEN 1 AND 5),
  CONSTRAINT chk_pet_sociabilidade CHECK (sociabilidade BETWEEN 1 AND 5),
  CONSTRAINT chk_pet_independencia CHECK (independencia BETWEEN 1 AND 5),
  CONSTRAINT chk_pet_custo CHECK (custo_manutencao BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. Solicitações de Adoção (Formulário de interesse e acompanhamento)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS solicitacoes_adocao (
  id_solicitacao INT PRIMARY KEY AUTO_INCREMENT,
  id_pet INT NOT NULL,
  id_adotante INT NOT NULL,
  tipo_moradia VARCHAR(50) NOT NULL,         -- Casa, Apartamento, etc.
  possui_outros_animais BOOLEAN NOT NULL DEFAULT FALSE,
  mensagem_interesse TEXT,
  status_solicitacao VARCHAR(30) NOT NULL DEFAULT 'Em Análise', -- 'Enviada', 'Em Análise', 'Aprovada', 'Recusada'
  data_solicitacao DATE NOT NULL,

  CONSTRAINT fk_solicitacoes_pet
    FOREIGN KEY (id_pet) REFERENCES pets(id_pet)
    ON DELETE CASCADE,
  CONSTRAINT fk_solicitacoes_adotante
    FOREIGN KEY (id_adotante) REFERENCES adotantes(id_adotante)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. Lista de Favoritos (Pets salvos pelo adotante)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favoritos (
  id_favorito INT PRIMARY KEY AUTO_INCREMENT,
  id_adotante INT NOT NULL,
  id_pet INT NOT NULL,

  CONSTRAINT uk_favoritos_adotante_pet UNIQUE (id_adotante, id_pet),
  CONSTRAINT fk_favoritos_adotante
    FOREIGN KEY (id_adotante) REFERENCES adotantes(id_adotante)
    ON DELETE CASCADE,
  CONSTRAINT fk_favoritos_pet
    FOREIGN KEY (id_pet) REFERENCES pets(id_pet)
    ON DELETE CASCADE
) ENGINE=InnoDB;
