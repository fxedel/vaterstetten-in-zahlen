[out:json][timeout:25];

area["boundary"="administrative"]["name"="Vaterstetten"]->.boundingarea;

(
    nwr(area.boundingarea)["amenity"="kindergarten"];
    nwr(area.boundingarea)["amenity"="childcare"];

    nwr(area.boundingarea)["construction:amenity"="kindergarten"];
    nwr(area.boundingarea)["construction:amenity"="childcare"];
);

out center;
