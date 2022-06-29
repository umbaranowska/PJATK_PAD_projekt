df = readRDS('wazne_informacje_procent.RDS')
write.csv(df, 'wazne_informacje.csv', fileEncoding = 'utf-8')
