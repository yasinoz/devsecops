# Lab Çözümü

Dockerfile `SONAR_TOKEN` argümanını bir bayrak olarak kullanıyor — doluysa
derlemeden sonra analiz çalıştırılıyor:

```
docker build -t hello-world-java --build-arg SONAR_TOKEN=$SONAR_TOKEN ./labs/static-analysis/hello-world-java
```

Tamamlandığında build geçecek ve projeyi şu adreste açabileceksiniz:
http://localhost:9000/dashboard?id=hello-world-java

_Project Settings_, sonra _Quality Gates_ tıklayıp özel kapınızı kullanacak
şekilde ayarlayın.

Şimdi `SONAR_ENFORCE_GATE` argümanı ayarlanmış halde bir build çalıştırın;
böylece kalite kontrolleri zorunlu olacak:

```
docker build -t hello-world-java --build-arg SONAR_TOKEN=$SONAR_TOKEN --build-arg SONAR_ENFORCE_GATE=true  ./labs/static-analysis/hello-world-java
```

Projeyi açın; kodda kritik bir güvenlik sorunu olduğunu göreceksiniz —
http://localhost:9000/project/issues?id=hello-world-java&resolved=false&severities=BLOCKER%2CCRITICAL%2CMAJOR%2CMINOR&types=VULNERABILITY

___
> [Alıştırmalara](README.tr.md) dönün.
