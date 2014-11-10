#
# Contributor: Carlos Ruiz - globalqss
# June 27, 2013
# Script to migrate from a 1.0c database to 2.0 - this one applies scripts on 1.0z folder
#
DATABASE=idempiere
USER=adempiere
JENKINSURL=http://ci.idempiere.org/job/iDempiere2.1

BASEDIR=`dirname $0`
cd $BASEDIR
wget -O post_pg.zip      "${JENKINSURL}/ws/migration/processes_post_migration/postgresql/*zip*/postgresql.zip"
mkdir -p post_pg
unzip -u -d post_pg post_pg.zip
> /tmp/lisFS.txt
for FOLDER in i1.0z
do
    wget -O ${FOLDER}_pg.zip "${JENKINSURL}/ws/migration/${FOLDER}/postgresql/*zip*/postgresql.zip"
    rm -rf ${FOLDER}_pg
    mkdir -p ${FOLDER}_pg
    unzip -u -d ${FOLDER}_pg ${FOLDER}_pg.zip

    psql -d $DATABASE -U $USER -q -t -c "select name from ad_migrationscript" | sed -e 's:^ ::' | grep -v '^$' | sort > /tmp/lisDB.txt
    if [ -d ${FOLDER}_pg/postgresql ]
    then
        cd ${FOLDER}_pg/postgresql
        ls *.sql | sort >> /tmp/lisFS.txt
        cd ../..
    fi
done
sort -o /tmp/lisFS.txt /tmp/lisFS.txt
sort -o /tmp/lisDB.txt /tmp/lisDB.txt
MSGERROR=""
APPLIED=N
for i in `comm -13 /tmp/lisDB.txt /tmp/lisFS.txt`
do
    SCRIPT=`find . -name "$i" -print`
    OUTFILE=/tmp/`basename "$i" .sql`.out
    psql -d $DATABASE -U $USER -f "$SCRIPT" 2>&1 | tee "$OUTFILE"
    if fgrep "ERROR:
FATAL:" "$OUTFILE" > /dev/null 2>&1
    then
        MSGERROR="$MSGERROR\n**** ERROR ON FILE $OUTFILE - Please verify ****"
    fi
    APPLIED=Y
done
if [ x$APPLIED = xY ]
then
    for i in post_pg/postgresql/*.sql
    do
        OUTFILE=/tmp/`basename "$i" .sql`.out
        psql -d $DATABASE -U $USER -f "$i" 2>&1 | tee "$OUTFILE"
        if fgrep "ERROR:
FATAL:" "$OUTFILE" > /dev/null 2>&1
        then
            MSGERROR="$MSGERROR\n**** ERROR ON FILE $OUTFILE - Please verify ****"
        fi
    done
fi
if [ -n "$MSGERROR" ]
then
    echo "$MSGERROR"
fi

