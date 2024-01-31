
# <p align="center">Ransomware ASM x64</p>
  
Ce projet à été effectué par:
- Ryan HENNOU
- Aurélien KRIEF
- Mathieu DUBOIS

Vidéo Youtube: 


## Attention:
Ce projet à été effectué dans un cadre scolaire. Les créateurs de celui-ci ne peuvent être tenus responsable de l'usage qu'il en sera fait ou des dommages causés sur des machines quelques qu'elles soient.
        

## 🧐 Fonctionnalités    
- Chiffrement de données
- Récupération de clef de chiffrement via socket
- Exfiltration de fichier via socket
- Déchiffrement



## 🧑🏻‍💻 Usage
Lancement du serveur python servant à :
- Héberger la clef de chiffrement
- Récupérer les fichiers exfiltrés
- Héberger la page web de rançon

Sur le serveur:
```
pip3 install -r requirements.txt

sudo python3 start_server.py
```

Compilation du ransomware:
```
nasm -f elf64 encrypt.asm ; ld -s encrypt.o -o encrypt ;
```

        
        
        
        
