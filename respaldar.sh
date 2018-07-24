#!/bin/bash
# DescripciÃn 
# Autor
# Fecha
# Version
# Nombre
. /opt/backup/config
if [ -e /opt/backup/.run.tmp ]; then
   echo "Se esta ejecutando un respaldo, si le sigue llegando este correo tiene una falla contacte al administrador" >> $INFOR
   echo "o verifique en memoria que en efecto hay un respaldo en proceso ps -ax" >> $INFOR
   echo "Si no existe nada en memoria, pruebe eliminando el archiv /opt/backup/.run.tmp y reejecute" >> $INFOR
   mutt -s "Informe horario de la syncronizacion" $CORREO < $INFOR 
   exit
else
 touch /opt/backup/.run.tmp 
 if [ ! -d $PRBACK ]; then
	mkdir $PRBACK
 fi
 if [ ! -d $PLBACK ]; then
 	mkdir $PLBACK
 fi
 echo "" > $ERR
 echo "*********** Informe de la sincronizacion ************" > $INFOR 
 for i in ${DBS[@]}; do
        #echo "1.- Genero el respaldo del Master"
	mysqldump -f -h $HOSTM --password=$PSWMR -u $i $i --ignore-error=warn > $PRBACK/$i.sql 2>> $ERR
        #echo "2.- Genero respaldo Local"
	mysqldump -f -h $HOSTS --password=$PSWSL -u root $i > $PLBACK/$i.sql 2>> $ERR
	#echo "3.- Borro la base de datos"
        mysql -u root --password=$PSWSL -e "drop database $i" 2>> $ERR
        mysql -u root --password=$PSWSL -e "create database $i" 2>> $ERR
        mysql -u root --password=$PSWSL $i < $PRBACK/$i.sql 2>> $ERR
         
        #echo "4.- Importo datos de la base de datos"
        #echo "5.- Notifico"
        echo $i: >> $INFOR
        ls -al $PLBACK|grep $i |awk '{print "El Respaldo viejo pesa: " $5 "bytes y tiene"}' >> $INFOR
        cat $PLBACK/$i.sql|wc -l >> $INFOR
        echo "lineas" >> $INFOR
        ls -al $PRBACK|grep $i |awk '{print "El Respaldo nuevo pesa: " $5 "bytes y tiene"}' >> $INFOR
        cat $PRBACK/$i.sql|wc -l >> $INFOR
        echo "lineas" >> $INFOR
        echo "#####################" >> $INFOR
        #echo "6.- Envio Correo"
        mutt -s "Informe horario de la syncronizacion" $CORREO < $INFOR
        #"echo "mysqlimport -D -h $HOSTS --password='$PSWSL' -u root $i $PRBACK/$i.sql"
 done
 DATE=`date`
 echo "##################" >> $INFOR
 echo "Ultima Ejecucion a las:" $DATE >> $INFOR
 echo "##################"i >> $INFOR
 rm /opt/backup/.run.tmp
fi
