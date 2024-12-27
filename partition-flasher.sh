#!/system/bin/sh                            
# Mendapatkan path direktori skrip yang sedang dijalankan
SCRIPT_DIR=$(dirname "$0")

# Menentukan path file yang akan diberikan izin eksekusi
FILE_TO_CHMOD="$SCRIPT_DIR/partition-flasher.sh"

# Memberikan izin eksekusi pada file yang dimaksud
chmod +x "$FILE_TO_CHMOD"

# Verifikasi apakah perintah berhasil
if [ $? -eq 0 ]; then
    echo "Perintah chmod +x berhasil dijalankan untuk $FILE_TO_CHMOD."
else
    echo "Terjadi kesalahan saat menjalankan chmod +x."
fi

echo "====================================="
echo " Universal Partition Flasher"
echo "====================================="

# Informasi Pengembang (mirip package.json)
echo "Pengembang: yudibilly"
echo "Versi: 1.0.0"
echo "Deskripsi: Skrip ini digunakan untuk mem-flash partisi dan membuat partisi baru dari file backup."
echo "Website: https://github.com/yudibilly/partition-flasher"
echo "Repositori: https://github.com/Gopartner/universal-partition-flasher.git"
echo "-------------------------------------"

# Peringatan awal
echo "PENTING!"
echo "1. Skrip ini akan memeriksa akses root untuk operasi flashing partisi."
echo "2. Akses root hanya dibutuhkan untuk mem-flash partisi yang memerlukannya."
echo "3. Pastikan Anda memahami risiko flashing partisi."
echo "4. Tekan Ctrl+C kapan saja untuk membatalkan."
echo "-------------------------------------"

# Memeriksa apakah perangkat memiliki akses root
if [ "$(id -u)" -ne 0 ]; then
    echo "Peringatan: Skrip ini membutuhkan akses root untuk mem-flash partisi."
    echo "Namun, beberapa operasi dapat dilakukan tanpa akses root. Pastikan Anda tahu apa yang akan diflash."
else
    echo "Akses root terdeteksi. Proses flashing partisi yang membutuhkan akses root akan dilanjutkan."
fi

# Mencari file img di seluruh penyimpanan
echo "Mencari file .img di seluruh penyimpanan, mohon tunggu..."
SEARCH_RESULTS=$(find /sdcard /mnt -type f -name "*.img" 2>/dev/null)

if [ -z "$SEARCH_RESULTS" ]; then
    echo "Error: Tidak ditemukan file .img di perangkat Anda."
    echo "Pastikan file .img ada di penyimpanan."
    exit 1
fi

echo "File .img ditemukan di lokasi berikut:"
echo "-------------------------------------"
INDEX=1
for FILE in $SEARCH_RESULTS; do
    echo "$INDEX. $FILE"
    FILE_PATHS[$INDEX]=$FILE
    INDEX=$((INDEX + 1))
done
echo "-------------------------------------"

# Meminta pengguna untuk memilih file
read -p "Pilih nomor file .img untuk diflash (1-$((INDEX - 1))): " CHOICE
if [ -z "${FILE_PATHS[$CHOICE]}" ]; then
    echo "Error: Pilihan tidak valid."
    exit 1
fi
SELECTED_FILE=${FILE_PATHS[$CHOICE]}
echo "Anda memilih: $SELECTED_FILE"

# Menampilkan partisi yang tersedia
echo "-------------------------------------"
echo "Mendeteksi partisi yang tersedia..."
AVAILABLE_PARTITIONS=$(ls /dev/block/by-name 2>/dev/null)
if [ -z "$AVAILABLE_PARTITIONS" ]; then
    echo "Error: Tidak ditemukan partisi yang dapat diflash!"
    exit 1
fi

INDEX=1
echo "Partisi yang tersedia:"
for PART in $AVAILABLE_PARTITIONS; do
    echo "$INDEX. $PART"
    PARTITIONS[$INDEX]=$PART
    INDEX=$((INDEX + 1))
done
echo "-------------------------------------"

# Meminta pengguna untuk memilih partisi
read -p "Pilih nomor partisi untuk diflash (1-$((INDEX - 1))): " PART_CHOICE
if [ -z "${PARTITIONS[$PART_CHOICE]}" ]; then
    echo "Error: Pilihan tidak valid."
    exit 1
fi
SELECTED_PART=${PARTITIONS[$PART_CHOICE]}
PART_PATH="/dev/block/by-name/$SELECTED_PART"
echo "Anda memilih partisi: $SELECTED_PART ($PART_PATH)"

# Konfirmasi dengan pengguna
echo "-------------------------------------"
read -p "Apakah Anda yakin ingin mem-flash file ini ke partisi $SELECTED_PART? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Flashing dibatalkan oleh pengguna."
    exit 1
fi

# Menambahkan opsi untuk membuat partisi dari file backup
echo "-------------------------------------"
read -p "Apakah Anda ingin membuat partisi baru dari file backup (misal: boot.img.win)? (y/n): " CREATE_PARTITION
if [ "$CREATE_PARTITION" == "y" ]; then
    echo "Mencari file backup dengan format tertentu (boot.img.win, dll)..."
    BACKUP_RESULTS=$(find /sdcard /mnt -type f -name "*.img.win" 2>/dev/null)

    if [ -z "$BACKUP_RESULTS" ]; then
        echo "Error: Tidak ditemukan file backup dengan format yang diinginkan (misal: boot.img.win)."
        exit 1
    fi

    echo "File backup ditemukan di lokasi berikut:"
    echo "-------------------------------------"
    INDEX=1
    for BACKUP_FILE in $BACKUP_RESULTS; do
        echo "$INDEX. $BACKUP_FILE"
        BACKUP_FILE_PATHS[$INDEX]=$BACKUP_FILE
        INDEX=$((INDEX + 1))
    done
    echo "-------------------------------------"

    # Meminta pengguna memilih file backup
    read -p "Pilih nomor file backup untuk digunakan (1-$((INDEX - 1))): " BACKUP_CHOICE
    if [ -z "${BACKUP_FILE_PATHS[$BACKUP_CHOICE]}" ]; then
        echo "Error: Pilihan tidak valid."
        exit 1
    fi
    SELECTED_BACKUP_FILE=${BACKUP_FILE_PATHS[$BACKUP_CHOICE]}
    echo "Anda memilih: $SELECTED_BACKUP_FILE"

    # Menanyakan apakah pengguna ingin membuat partisi baru
    echo "Membuat partisi baru dengan file backup..."
    # Logika untuk pembuatan partisi, misalnya dd atau menggunakan alat lain
    echo -n "Proses pembuatan partisi dengan file backup $SELECTED_BACKUP_FILE dimulai"
    for i in {1..10}; do
        sleep 1
        echo -n "."
    done
    echo " Selesai!"
    # Contoh perintah untuk membuat partisi (harus disesuaikan dengan perangkat dan format file):
    dd if="$SELECTED_BACKUP_FILE" of="$PART_PATH"

    if [ $? -eq 0 ]; then
        echo "Partisi baru berhasil dibuat dari file $SELECTED_BACKUP_FILE!"
    else
        echo "Error: Gagal membuat partisi baru!"
        exit 1
    fi
fi

# Flash file img ke partisi jika akses root tersedia
if [ "$(id -u)" -eq 0 ]; then
    echo -n "Memulai proses flashing..."
    for i in {1..10}; do
        sleep 1
        echo -n "."
    done
    dd if="$SELECTED_FILE" of="$PART_PATH"
    if [ $? -eq 0 ]; then
        echo " File $SELECTED_FILE berhasil diflash ke partisi $SELECTED_PART!"
    else
        echo "Error: Gagal mem-flash file ke partisi $SELECTED_PART!"
        exit 1
    fi
else
    echo "Tanpa akses root, proses flashing tidak dapat dilakukan pada partisi."
    echo "Anda hanya dapat memilih operasi yang tidak memerlukan akses root."
fi

echo "-------------------------------------"
echo "Proses selesai!"
echo "====================================="
