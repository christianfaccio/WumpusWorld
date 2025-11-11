/**
* Name: Wumpus World
* Author: Christian Faccio
* Tags: 
*/

model wumpus

global {
	int x <- 25;
	int y <- x; // square always
	int n_gold <- 2;
	int n_wumpus <- 1;
	int n_pit <- 3;
	int n_players <- 1;
	float weight <- 1.0;
	int final_cycle <- 0;
	
	// output
	int won <- 0;
	int lost <- 0;
	
	// BELIEFS
	predicate want_to_patrol <- new_predicate("want_to_patrol");
	predicate feel_glitter <- new_predicate("feel_glitter");
	predicate feel_odor <- new_predicate("feel_odor");
	predicate feel_breeze <- new_predicate("feel_breeze");
	
	// DESIRES
	predicate patrol <- new_predicate("patrol");
	predicate collect_gold <- new_predicate("collect_gold");
	predicate avoid_wumpus <- new_predicate("avoid_wumpus");
	predicate avoid_pit <- new_predicate("avoid_pit");
	predicate choose_location <- new_predicate("choose_location");
	
	reflex update_cycle {
		final_cycle <- cycle;
	}
	 
	init {
		create goldArea number: n_gold;
		create wumpusArea number: n_wumpus;
		create pitArea number: n_pit;
		create player number: n_players;
	}
}


grid gworld width: x height: y neighbors:4 {
	rgb color <- rgb(0,3,51);
	//list<gworld> neighbors <- (self neighbors_at 1);
}

species odorArea{
	aspect base {
	  draw square(4) color: #brown border: #black;		
	}
}
species glitterArea{
	aspect base {
	  draw square(4) color: #gold border: #black;		
	}
}
species breezeArea{
	aspect base {
	  draw square(4) color: #lightblue border: #black;		
	}
}

species pitArea{
	image_file icon <- image_file('../includes/pit.jpg');
	gworld place <- one_of(gworld);
	init {
		
		location <- place.location;
		
		loop i over: place.neighbors {
			create breezeArea{
				location <- i.location;
			}
		}
	
	}
	
	aspect base {
	  draw square(4) color: #blue border: #black;		
	}
	aspect icon {
		draw icon size: 4.0;
	}
}
species wumpusArea{
	image_file icon <- image_file('../includes/wumpus.png');
	gworld place <- one_of(gworld);
	init {
		
		location <- place.location;
		
		loop i over: place.neighbors {
			create odorArea{
				location <- i.location;
			}
		}
	}
	aspect base {
	  draw square(4) color: #red border: #black;		
	}
	aspect icon {
		draw icon size: 4.0;
	}
}
species goldArea{
	image_file icon <- image_file('../includes/gold.jpg');
	gworld place <- one_of(gworld);
	list<glitterArea> my_glitters <- [];  // Track created glitters
	
	init {
		
		location <- place.location;
		
		loop i over: place.neighbors {
			create glitterArea{
				location <- i.location;
				myself.my_glitters << self;
			}
		}
	}
	
	aspect base {
	  draw square(4) color: #yellow border: #black;		
	}
	aspect icon {
		draw icon size: 4.0;
	}
}

species player skills:[moving] control: simple_bdi {
	
	gworld place <- one_of(gworld);
	
	// BDI params --------------------------------------------------------------------------------------
	
	point target;
	list<point> memory <- [];		// defines the memory of the player 
	gworld previous_cell;
	
	// Init --------------------------------------------------------------------------------------
	
	init {
		location <- place.location;
		//memory <+ place.location; // needed for ADVANCED concepts
		
		do add_belief(want_to_patrol); // initialize agent with belief to go around (patrol)
	}
	
	// Actions --------------------------------------------------------------------------------------
	
	action choose_escape_cell {
        float rnd_nb <- rnd(1.0);
        if (rnd_nb <= weight) {
        	if (previous_cell != nil) {
        		return previous_cell;
        	}
        } else {
        	list<gworld> other_neighbors <- place.neighbors - previous_cell;
        	return one_of(other_neighbors);
        }
    }
	
	// Perceptions --------------------------------------------------------------------------------------
	
	perceive gold target: goldArea in: 0.0 {
	    list<glitterArea> glitters_to_remove <- self.my_glitters;
	    
	    ask myself {
	    	do remove_intention(collect_gold);
	        do remove_belief(feel_glitter);
	        do add_belief(want_to_patrol);
	        do add_desire(patrol);
	        do add_intention(patrol);
	        n_gold <- n_gold - 1;
	        if (n_gold = 0) {
	        	won <- 1;
	        }
	        memory <- [];
	    }
	    
	    ask glitters_to_remove {
	        do die;
	    }

	    do die; 
	}
	perceive wumpus target: wumpusArea in: 0.0{
		ask myself {
			lost <- 1;
			do die;
		}
	}
	perceive pit target: pitArea in: 0.0{
		ask myself {
			lost <- 1;
	    	do die;
		}
	}
	perceive glitter target: glitterArea in: 0.0{
		ask myself {
			do remove_intention(patrol, true);
			do remove_belief(want_to_patrol);
			do add_belief(feel_glitter);
			do add_desire(collect_gold);
			do add_intention(collect_gold);
		}
	}
	perceive odor target: odorArea in: 0.0{
		ask myself {
			do remove_intention(patrol, true);
			do remove_belief(want_to_patrol);
			do add_belief(feel_odor);
			do add_desire(avoid_wumpus);
			do add_intention(avoid_wumpus);
		}
	}
	perceive breeze target: breezeArea in: 0.0{
		ask myself {
			do remove_intention(patrol, true);
			do remove_belief(want_to_patrol);
			do add_belief(feel_breeze);
			do add_desire(avoid_pit);
			do add_intention(avoid_pit);
		}
	}
	
	// Rules --------------------------------------------------------------------------------------
	
	rule belief: want_to_patrol new_desire: patrol strength: 0.5;
	rule belief: feel_glitter new_desire: collect_gold strength: 3.0;
	rule belief: feel_breeze new_desire: avoid_pit strength: 1.0;
	rule belief: feel_odor new_desire: avoid_wumpus strength: 2.0;
	
	// Plans --------------------------------------------------------------------------------------
	
	plan move_random intention: patrol {
        previous_cell <- place;  // Store current position before moving
        gworld new_place <- one_of(place.neighbors);
        place <- new_place;
        location <- new_place.location;
    }
	plan get_gold intention: collect_gold {
        if (length(memory) = 0) {
            loop neighbor over: place.neighbors {
                memory <+ neighbor.location;
            }
        }
        
        if (length(memory) > 0) {
            previous_cell <- place;  // Store before moving
            point next_location <- memory[0];
            place <- gworld(next_location);  
            location <- next_location;        
            memory >- first(memory);          
        } else {
            do remove_belief(feel_glitter);
            do add_belief(want_to_patrol);
        }
    }
	plan escape_pit intention: avoid_pit {
	    // Choose escape cell probabilistically
	    gworld escape_cell <- self.choose_escape_cell();
	    
	    if (escape_cell != nil) {
	        previous_cell <- place;  // Update previous before moving
	        place <- escape_cell;
	        location <- escape_cell.location;
	    }
	    
	    // Clear the danger belief after escaping
	    do remove_intention(avoid_pit);
	    do remove_belief(feel_breeze);
	    do add_belief(want_to_patrol);
	    do add_desire(patrol);
	    do add_intention(patrol);
	}
	plan escape_wumpus intention: avoid_wumpus {
	    // Choose escape cell probabilistically
	    gworld escape_cell <- self.choose_escape_cell();
	    
	    if (escape_cell != nil) {
	        previous_cell <- place;  // Update previous before moving
	        place <- escape_cell;
	        location <- escape_cell.location;
	    }
	    
	    // Clear the danger belief after escaping
	    do remove_intention(avoid_wumpus);
	    do remove_belief(feel_odor);
	    do add_belief(want_to_patrol);
	    do add_desire(patrol);
	    do add_intention(patrol);
	}
	
	// Aspect --------------------------------------------------------------------------------------
	
	aspect base {
		draw circle(1) color: #white;
	}
}

experiment test type: gui {
	parameter "Grid x:" var: x min: 0 max: 1000;
	parameter "Grid y:" var: y min: 0 max: 1000;
	parameter "Number of gold spots:" var: n_gold init: 1;
	parameter "Number of wumpuses:" var: n_wumpus init: 1;
	parameter "Number of pits:" var: n_pit init: 3;
	
	output {					
		display view1 { 
			grid gworld border: #white;
			species goldArea aspect:icon;
			species glitterArea aspect:base;
			species wumpusArea aspect:icon;
			species odorArea aspect:base;
			species pitArea aspect:icon;
			species breezeArea aspect: base;
			species player aspect: base;
		}
	}
}

experiment grid_size type: batch until: (n_gold=0 or n_players=0 or cycle>10000) repeat: 2 {
	parameter "Grid size" var: x min: 20 max: 100 step:2;
	
	reflex save_results {
		ask simulations {
			save [won, lost, n_gold, cycle] 
			to: "grid_size_stochastic.csv" format: "csv" rewrite: false;
		}
	}	
}

experiment weight type: batch until: (won=1 or lost=1 or final_cycle>10000) repeat: 20 {
	parameter "Weight" var: weight min: 0.5 max: 1.0 step: 0.05;
	
	reflex save_results {
		ask simulations {
			save [weight, won, lost, n_gold, final_cycle] 
			to: "../analysis/results/weight_results.csv" format: "csv" rewrite: false;
		}
	}
}

