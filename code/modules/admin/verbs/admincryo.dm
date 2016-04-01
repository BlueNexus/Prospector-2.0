/proc/get_access(job)
	switch(job)
		if("Geneticist")
			return list(access_medical, access_morgue, access_genetics)
		if("Station Engineer")
			return list(access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels, access_external_airlocks, access_construction)
		if("Assistant")
			if(config.assistant_maint)
				return list(access_maint_tunnels)
			else
				return list()
		if("Chaplain")
			return list(access_morgue, access_chapel_office, access_crematorium)
		if("Detective")
			return list(access_sec_doors, access_forensics_lockers, access_morgue, access_maint_tunnels)
		if("Medical Doctor")
			return list(access_medical, access_morgue, access_surgery)
		if("Gardener")	// -- TLE
			return list(access_hydroponics, access_morgue) // Removed tox and chem access because STOP PISSING OFF THE CHEMIST GUYS // //Removed medical access because WHAT THE FUCK YOU AREN'T A DOCTOR YOU GROW WHEAT //Given Morgue access because they have a viable means of cloning.
		if("Librarian") // -- TLE
			return list(access_library)
		if("Lawyer") //Muskets 160910
			return list(access_lawyer, access_sec_doors)
		if("Captain")
			return get_all_accesses()
		if("Crew Supervisor")
			return list(access_security, access_sec_doors, access_brig)
		if("Correctional Advisor")
			return list(access_security, access_sec_doors, access_brig, access_armory)
		if("Scientist")
			return list(access_tox, access_tox_storage, access_research, access_xenobiology)
		if("Safety Administrator")
			return list(access_medical, access_morgue, access_tox, access_tox_storage, access_chemistry, access_genetics,
			            access_teleporter, access_heads, access_tech_storage, access_security, access_sec_doors, access_brig, access_atmospherics,
			            access_maint_tunnels, access_bar, access_janitor, access_kitchen, access_robotics, access_armory, access_hydroponics,
			            access_research, access_hos, access_RC_announce, access_forensics_lockers, access_keycard_auth, access_gateway)
		if("Head of Personnel")
			return list(access_security, access_sec_doors, access_brig, access_forensics_lockers,
			            access_tox, access_tox_storage, access_chemistry, access_medical, access_genetics, access_engine,
			            access_emergency_storage, access_change_ids, access_ai_upload, access_eva, access_heads,
			            access_all_personal_lockers, access_tech_storage, access_maint_tunnels, access_bar, access_janitor,
			            access_crematorium, access_kitchen, access_robotics, access_cargo, access_cargo_bot, access_mailsorting, access_qm, access_hydroponics, access_lawyer,
			            access_chapel_office, access_library, access_research, access_mining, access_heads_vault, access_mining_station,
			            access_hop, access_RC_announce, access_keycard_auth, access_gateway)
		if("Atmospheric Technician")
			return list(access_atmospherics, access_maint_tunnels, access_emergency_storage, access_construction)
		if("Bartender")
			return list(access_bar)
		if("Chemist")
			return list(access_medical, access_chemistry)
		if("Janitor")
			return list(access_janitor, access_maint_tunnels)
		if("Chef")
			return list(access_kitchen, access_morgue)
		if("Roboticist")
			return list(access_robotics, access_tech_storage, access_morgue) //As a job that handles so many corpses, it makes sense for them to have morgue access.
		if("Cargo Technician")
			return list(access_maint_tunnels, access_cargo, access_cargo_bot, access_mailsorting)
		if("Shaft Miner")
			return list(access_mining, access_mining_station)
		if("Quartermaster")
			return list(access_maint_tunnels, access_mailsorting, access_cargo, access_cargo_bot, access_qm, access_mining, access_mining_station)
		if("Chief Engineer")
			return list(access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels,
			            access_teleporter, access_external_airlocks, access_atmospherics, access_emergency_storage, access_eva,
			            access_heads, access_ai_upload, access_construction, access_robotics,
			            access_ce, access_RC_announce, access_keycard_auth, access_tcomsat, access_sec_doors)
		if("Research Director")
			return list(access_rd, access_heads, access_tox, access_genetics,
			            access_tox_storage, access_teleporter,
			            access_research, access_robotics, access_xenobiology,
			            access_RC_announce, access_keycard_auth, access_tcomsat, access_gateway, access_sec_doors)
		if("Virologist")
			return list(access_medical, access_virology)
		if("Chief Medical Officer")
			return list(access_medical, access_morgue, access_genetics, access_heads,
			access_chemistry, access_virology, access_cmo, access_surgery, access_RC_announce,
			access_keycard_auth, access_sec_doors)
		else
			return list()

/client/proc/admincryo(var/mob/living/M in mob_list)
	set category = "Special Verbs"
	set name = "Admin Cryo"
	if(!holder)
		src << "Only administrators may use this command."
		return
	if(!M)
		return
	if(!istype(M))
		alert("Cannot cryo a ghost")
		return

	var/confirm = alert(src, "You will be removing [M] from the round, are you sure?", "Message", "Yes", "No")
	if(confirm != "Yes")
		return
	if(M.client)
		confirm = alert(src, "Would you like to ghost [M.key]?", "Message", "Yes", "No", "Cancel")
		if(confirm == "Cancel")
			return

	var/job = "Assistant"
	if(M.mind && M.mind.assigned_role)
		job = M.mind.assigned_role

	for(var/obj/item/Player_Inventory in M)
		if(istype(Player_Inventory, /obj/item/organ))
			qdel(Player_Inventory)

	var/obj/structure/closet/crate/secure/K = new /obj/structure/closet/crate/secure/(M.loc)
	K.req_access += get_access(job)
	K.name = (M.real_name + " - " + job + " - SSD Crate")
	K.health = 1000000
	K.contents = M.contents
	for(var/datum/objective/O in all_objectives)
		if(O.target && istype(O.target,/datum/mind))
			if(O.target == M.mind)
				if(O.owner && O.owner.current)
					O.owner.current << "\red You get the feeling your target is no longer within your reach. Time for Plan [pick(list("A","B","C","D","X","Y","Z"))]..."
				O.target = null
				spawn(1) //This should ideally fire after the M is deleted.
					if(!O) return
					O.find_target()
					if(!(O.target))
						all_objectives -= O
						O.owner.objectives -= O
						qdel(O)

	//Handle job slot/tater cleanup.
	job_master.FreeRole(job)

	if(M.mind && M.mind.objectives.len)
		qdel(M.mind.objectives)
		M.mind.special_role = null

	// Delete them from datacore.

	if(PDA_Manifest.len)
		PDA_Manifest.Cut()
	for(var/datum/data/record/R in data_core.medical)
		if ((R.fields["name"] == M.real_name))
			qdel(R)
	for(var/datum/data/record/T in data_core.security)
		if ((T.fields["name"] == M.real_name))
			qdel(T)
	for(var/datum/data/record/G in data_core.general)
		if ((G.fields["name"] == M.real_name))
			qdel(G)

	//Make an announcement and log the person entering storage.
	//frozen_crew += "[M.real_name]"

	log_and_message_admins("\blue [key_name_admin(usr)] has admin cryoed [key_name(M)]")

	// Delete the mob.
	//This should guarantee that ghosts don't spawn.
	if(confirm)
		M.ghostize()
	M.ckey = null
	qdel(M)
	M = null
	return
