//Tramvaj sistem

#include <a_samp>

#define MAX_PLAYERS (1000)

new test_id = 0, // Obrisati ukoliko se ne koristi testna komanda
	tramvaj_kazna[MAX_PLAYERS] = 0,
	sverc_provjera[MAX_PLAYERS] = 0,
	bool:dnevna_karta[MAX_PLAYERS] = false;

const DIALOG_TRAMVAJ = 999,
	// Cijena kupovine karte za jednu voznju
	  cijena_karte = 1000,
	// Cijena kazne koju ce igrac dobiti ukoliko ga uhvate da se sverca
	  cijena_kazne = 5000,
	// Cijena dnevne karte koju moze koristiti sve dok je online
	  cijena_dnevnekarte = 10000;

// (X, Y, Z, Rotacija, Lijevo/Desno) - Lijevo = 0, Desno = 1
// Lijevo/Desno - Pozicija aktora u odnosu na tramvaj. 
// Primjer: Prvi tramvaj je na zeljeznici, i aktoru je lakse pristupiti sa lijeve strane. Ostali tramvaji su u desnoj traci, pa im je lakse pristupiti sa desne strane. 
static const Float:tramvaj_pozicije[11][5] =
{
	{2284.8750, -1326.1179, 25.5, 1.0, 0.0}, 		// Zeljeznica
	{1152.3308, -1657.2321, 14.5, 1.0, 1.0}, 		// Plaza
	{1340.5618, -1318.0380, 14.0, 181.0, 1.0}, 		// GunShop
	{1570.2349, -1102.8933, 24.5, 193.2837, 1.0}, 	// Banka
	{1712.5287, -1280.9269, 14.5, 181.0, 1.0}, 		// Glen Park
	{2870.7908, -1199.1302, 11.5, 189.7571, 1.0}, 	// Ispod zeljeznice
	{2826.9871, -1787.5569, 11.5, 172.8, 1.0}, 		// Arena
	{2203.9238, -2345.7798, 14.5, 134.9, 1.0}, 		// Industrijska zona
	{1349.7042, -2284.8792, 14.5, 1.2892, 1.0}, 	// Aerodrom
	{1391.6307, -1753.5834, 14.5, 1.0, 1.0}, 		// Centar
	{542.0250, -1714.0490, 14.0, 82.6382, 1.0} 		// Plaza
};

//Koordinate mjesta gdje se moze uzeti dnevna karta
static const Float:kupovina_dnevne[2][3] =
{
	{1753.0159, -1902.8800, 13.5631},
	{0.0, 0.0, 0.0}
};

main() 
{
	print(" ");
}

public OnFilterScriptInit()
{
	KreirajTramvaj();
	KreirajAktora();
	KreirajLabelPickup();
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    // Test komanda za teleportaciju do tramvaja, nije obavezna za rad skripte
    if(!strcmp(cmdtext, "/testkomanda", true))
    {
        switch(test_id)
        {
        	case 0:
        		SetPlayerPos(playerid, 2284.8750, -1326.1179, 24.6223+5), test_id++;
        	case 1:
        		SetPlayerPos(playerid, 1152.3308, -1657.2321, 13.9058+5), test_id++;
        	case 2:
        		SetPlayerPos(playerid, 1340.5618, -1318.0380, 13.4830+5), test_id++;
        	case 3:
        		SetPlayerPos(playerid, 1563.8398, -1085.6283, 23.5989+5), test_id++;
        	case 4:
        		SetPlayerPos(playerid, 1712.5287, -1280.9269, 13.4753+5), test_id++;
        	case 5:
        		SetPlayerPos(playerid, 2870.7908, -1199.1302, 10.9751+5), test_id++;
        	case 6:
        		SetPlayerPos(playerid, 2826.9871, -1787.5569, 10.9673+5), test_id++;
        	case 7:
        		SetPlayerPos(playerid, 2203.9238, -2345.7798, 13.4673+5), test_id++;
        	case 8:
        		SetPlayerPos(playerid, 542.0250, -1714.0490, 13.0116+5), test_id++;
        	case 9:
        		SetPlayerPos(playerid, 1349.7042, -2284.8792, 13.4827+5), test_id++;
        	case 10:
        		SetPlayerPos(playerid, 1391.6307, -1753.5834, 13.4752+5), test_id++;
        	default:
        		SetPlayerPos(playerid, 2284.8750, -1326.1179, 24.6223+5), test_id = 0;
        }
        return 1;     
    }
    return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	// Otvaranje dialoga za odabir stajalista na tipku 'Y'
	if(newkeys & KEY_YES)
    {
    	for(new tramvaj_id = 0; tramvaj_id < sizeof(tramvaj_pozicije); tramvaj_id++)
		{
			if(IsPlayerInRangeOfPoint(playerid, 7.0, tramvaj_pozicije[tramvaj_id][0], tramvaj_pozicije[tramvaj_id][1], tramvaj_pozicije[tramvaj_id][2]))
			{
				ShowPlayerDialog(playerid, DIALOG_TRAMVAJ, DIALOG_STYLE_LIST,"Stajalista tramvaja","Zeljeznica\nPlaza Sjever\nGunShop\nBanka\nGlenPark\nIspod zeljeznice\nArena\nIndustrijska zona\nAerodrom\nCentar\nPlaza Jug","Odaberi","Zatvori");	
			}
		}
		for(new labelpickup_id = 0; labelpickup_id < sizeof(kupovina_dnevne); labelpickup_id++)
		{	
			if(IsPlayerInRangeOfPoint(playerid, 5.0, kupovina_dnevne[labelpickup_id][0], kupovina_dnevne[labelpickup_id][1], kupovina_dnevne[labelpickup_id][2]))
			{
				if(dnevna_karta[playerid] == true) return SendClientMessage(playerid, -1, "Vec imate dnevnu kartu.");
				if(GetPlayerMoney(playerid) < cijena_dnevnekarte) return SendClientMessage(playerid, -1, "Nemate dovoljno novca.");
				new string[48];
				format(string,sizeof(string), "Uzeli ste dnevnu kartu, platili ste $%d.", cijena_dnevnekarte);
				SendClientMessage(playerid, -1, string);
				dnevna_karta[playerid] = true;
				GivePlayerMoney(playerid, -cijena_dnevnekarte);
			}
		}
    }

    // Otvaranje dialoga za sverc odabir stajalista na tipku 'N'
    if(newkeys & KEY_NO)
    {
    	for(new tramvaj_id = 0; tramvaj_id < sizeof(tramvaj_pozicije); tramvaj_id++)
		{
			if(IsPlayerInRangeOfPoint(playerid, 7.0, tramvaj_pozicije[tramvaj_id][0], tramvaj_pozicije[tramvaj_id][1], tramvaj_pozicije[tramvaj_id][2]))
			{
				if(dnevna_karta[playerid] == true) return SendClientMessage(playerid, -1, "Imate dnevnu kartu, ne mozete se svercati");
				sverc_provjera[playerid] = 1;
				new string[85];
				format(string,sizeof(string), "Odabrali ste opciju svercanja, ukoliko vas uhvate kazna je $%d. Sansa je 1/5.", cijena_kazne);
				SendClientMessage(playerid, -1, string);
				ShowPlayerDialog(playerid, DIALOG_TRAMVAJ, DIALOG_STYLE_LIST,"Sverc - Stajalista tramvaja","Zeljeznica\nPlaza Sjever\nGunShop\nBanka\nGlenPark\nIspod zeljeznice\nArena\nIndustrijska zona\nAerodrom\nCentar\nPlaza Jug","Odaberi","Zatvori");	
			}
		}
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
	dnevna_karta[playerid] = false;
	tramvaj_kazna[playerid] = 0;
	sverc_provjera[playerid] = 0;
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	// Ukoliko igrac koji je umro posjeduje dnevnu kartu, postoji 1/3 sansa da ju izgubi zbog smrti
	if(dnevna_karta[playerid] == true)
	{
		tramvaj_kazna[playerid] = random(3);
		if(tramvaj_kazna[playerid] == 2) return SendClientMessage(playerid, -1, "Izgubili ste dnevnu kartu jer ste umrli."), dnevna_karta[playerid] = false;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_TRAMVAJ:
		{
			if(response)
			{
				switch(listitem)
				{					
					default:
					{
						if(IsPlayerInRangeOfPoint(playerid, 10, tramvaj_pozicije[listitem][0], tramvaj_pozicije[listitem][1], tramvaj_pozicije[listitem][2])) return SendClientMessage(playerid, -1, "Nalazite se vec na tom stajalistu");
						if(dnevna_karta[playerid] == false)
						{
							if(sverc_provjera[playerid] == 0) 
							{
								if(GetPlayerMoney(playerid) < cijena_karte) return SendClientMessage(playerid, -1, "Nemate dovoljno novca.");
								new string[48];
								format(string,sizeof(string), "Odabrali ste stajaliste, cijena je $%d.", cijena_karte);
								SendClientMessage(playerid, -1, string);
								GivePlayerMoney(playerid, -cijena_karte);
							}
							else
							{
								tramvaj_kazna[playerid] = random(5);
								if(tramvaj_kazna[playerid] == 4) return SendClientMessage(playerid, -1, "Uhvaceni ste prilikom svercanja."), GivePlayerMoney(playerid, -cijena_kazne);
								SendClientMessage(playerid, -1, "Prosli ste kontrolu, nisu vas uhvatili.");
								sverc_provjera[playerid] = 0;
							}
						}
						else
						{
							SendClientMessage(playerid, -1, "Odabrali ste stajaliste. Vi imate dnevnu kartu i ne placate voznju.");
						}
						SendClientMessage(playerid, -1, "Sacekajte 5 sekundi dok dodete na stajaliste.");
						SetPlayerPos(playerid, 1.54, 23.31, 1200.0);
						SetPlayerInterior(playerid, 1);
						SetTimerEx("Teleportacija_Stajaliste", 5000, 0, "ii", playerid, listitem);
					}
				}
			}
			else return SendClientMessage(playerid, -1, "Napustili ste dialog.");
		}
	}
	return 1;
}

//Teleportovanje igraca do stajalista
forward Teleportacija_Stajaliste(playerid, tramvaj_stajaliste);
public Teleportacija_Stajaliste(playerid, tramvaj_stajaliste)
{
	new Float:Actor_X, Float:Actor_Y, Float:Actor_Z, Float:Rotacija;
	GetActorPos(tramvaj_stajaliste, Actor_X, Actor_Y, Actor_Z);
	GetActorFacingAngle(tramvaj_stajaliste, Rotacija);
	if(Rotacija > 0 && Rotacija < 135)
	{
		SendClientMessage(playerid, -1, "Dosli ste na stajaliste.");
		SetPlayerInterior(playerid, 0);
		SetPlayerPos(playerid, Actor_X-1.5, Actor_Y, Actor_Z);
	}
	else
	{
		SendClientMessage(playerid, -1, "Dosli ste na stajaliste.");
		SetPlayerInterior(playerid, 0);
		SetPlayerPos(playerid, Actor_X+1.5, Actor_Y, Actor_Z);
	}
	return 1;
}

// Kreiranje tramvaja
KreirajTramvaj()
{
	for(new tramvaj_id = 0; tramvaj_id < sizeof(tramvaj_pozicije); tramvaj_id++)
	{
		AddStaticVehicle(590, tramvaj_pozicije[tramvaj_id][0], tramvaj_pozicije[tramvaj_id][1], tramvaj_pozicije[tramvaj_id][2], tramvaj_pozicije[tramvaj_id][3], -1, -1);
		Create3DTextLabel("Tramvaj\n\
					   	   {FFFFFF}Da udjete u tramvaj, kupite kartu kod konduktera i odaberite relaciju.\n( Y )\n\nUkoliko se zelite svercati\n( N )", 0xFF2200FF, tramvaj_pozicije[tramvaj_id][0], tramvaj_pozicije[tramvaj_id][1], tramvaj_pozicije[tramvaj_id][2], 25,0,1);
	}
}

// Kreiranje actora
KreirajAktora()
{
	for(new aktor_id = 0; aktor_id < sizeof(tramvaj_pozicije); aktor_id++)
	{
		if(tramvaj_pozicije[aktor_id][3] > 0 && tramvaj_pozicije[aktor_id][3] < 90)
		{
			if(tramvaj_pozicije[aktor_id][4] == 1.0) CreateActor(171, tramvaj_pozicije[aktor_id][0]+2.5, tramvaj_pozicije[aktor_id][1]+2.5, tramvaj_pozicije[aktor_id][2], tramvaj_pozicije[aktor_id][3]-90);
			else CreateActor(171, tramvaj_pozicije[aktor_id][0]-2.5, tramvaj_pozicije[aktor_id][1]+2.5, tramvaj_pozicije[aktor_id][2], tramvaj_pozicije[aktor_id][3]+90);
		}
		else if(tramvaj_pozicije[aktor_id][3] > 90 && tramvaj_pozicije[aktor_id][3] < 135)
		{
			if(tramvaj_pozicije[aktor_id][4] == 1.0) CreateActor(171, tramvaj_pozicije[aktor_id][0]+1, tramvaj_pozicije[aktor_id][1]+4, tramvaj_pozicije[aktor_id][2], tramvaj_pozicije[aktor_id][3]-90);
			else CreateActor(171, tramvaj_pozicije[aktor_id][0]+1, tramvaj_pozicije[aktor_id][1]-4, tramvaj_pozicije[aktor_id][2], tramvaj_pozicije[aktor_id][3]+90);
		}
		else
		{
			if(tramvaj_pozicije[aktor_id][4] == 1.0) CreateActor(171, tramvaj_pozicije[aktor_id][0]-3, tramvaj_pozicije[aktor_id][1]+3, tramvaj_pozicije[aktor_id][2], tramvaj_pozicije[aktor_id][3]-90);
			else CreateActor(171, tramvaj_pozicije[aktor_id][0]+2.5, tramvaj_pozicije[aktor_id][1]+2.5, tramvaj_pozicije[aktor_id][2], tramvaj_pozicije[aktor_id][3]+90);
		}
	}
}

//Kreiranje Labela i Pickupa gdje se uzima dnevna karta
KreirajLabelPickup()
{
	for(new labelpickup_id = 0; labelpickup_id < sizeof(kupovina_dnevne); labelpickup_id++)
	{
		CreatePickup(19606, 1, kupovina_dnevne[labelpickup_id][0], kupovina_dnevne[labelpickup_id][1], kupovina_dnevne[labelpickup_id][2]);
		Create3DTextLabel("Tramvaj\n\
						   {FFFFFF}Da uzmete dnevnu kartu stisnite\n( Y )", 0xFF2200FF, kupovina_dnevne[labelpickup_id][0], kupovina_dnevne[labelpickup_id][1], kupovina_dnevne[labelpickup_id][2], 25,0,1);
	}
}
