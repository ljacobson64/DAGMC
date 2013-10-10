// MCNP5/dagmc/meshtal_funcs.cpp

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <fstream>
#include <sstream>

#include "meshtal_funcs.h"
#include "TallyManager.hpp"

// TODO modify/remove this method when tally multipliers are implemented
void mcnp_weight_calculation(int* index, double* erg, double* wgt, 
                              double* dist, double* score_result)
{
    FMESH_FUNC(dagmc_mesh_score)(index, erg, wgt, dist, score_result);
}

// create a tally manager to handle all DAGMC tally actions
TallyManager tallyManager = TallyManager();

//---------------------------------------------------------------------------//
// INITIALIZATION AND SETUP METHODS
//---------------------------------------------------------------------------//
/**
 * \brief Convert contents of FC card to multimap<string, string>
 * \param fc_content the FC card's comment content as a string
 * \param fmesh_params the output data and comments, as a multimap
 * \param fcid the tally ID of the FC card
 * \return true on success; false if input has serious formatting problems
 *         to make parameter parsing impossible
 */
static void parse_fc_card(std::string& fc_content,
                          std::multimap<std::string, std::string>& fmesh_params,
                          int fcid)
{
    // convert '=' chars to spaces 
    size_t found;
    found = fc_content.find_first_of('=');

    while (found!= fc_content.npos)
    {
        fc_content[found] = ' ';
        found = fc_content.find_first_of('=',found+1);
    }

    std::stringstream tokenizer(fc_content);

    // skip tokens until 'dagmc' found
    bool found_dagmc = false;

    while(tokenizer)
    {
        std::string dagmc; 
        tokenizer >> dagmc;
        if(dagmc == "dagmc")
        {
            found_dagmc = true;
            break;
        }
    }

    if(!found_dagmc)
    {
        std::cerr << "Error: FC" << fcid << " card is incorrectly formatted" << std::endl;
        exit(EXIT_FAILURE);
    }

    std::string last_key;

    while(tokenizer)
    {
        std::string token;
        tokenizer >> token;

        if( token == "" ) continue;
        if( token == "-dagmc") break; // stop parsing if -dagmc encountered

        if( last_key == "" ){ last_key = token; }
        else
        { 
            fmesh_params.insert(std::make_pair(last_key,token));
            last_key = "";
        }
    }

    if( last_key != "" )
    {
        std::cerr << "Warning: FC" << fcid << " card has unused key '" 
                  << last_key << "'" << std::endl;
    }
}
//---------------------------------------------------------------------------//
/**
 * \brief Copy comment string from fortran's data structure
 * \param fort_comment the comment string to copy
 * \param n_comment_lines the number of comment lines
 * \return a std::string version of the original comment string
 */
std::string copyComments(char* fort_comment, int* n_comment_lines)
{
    std::string comment_str; 

    const unsigned int fort_line_len = 75;
    unsigned int comment_len = fort_line_len * *n_comment_lines;

    // Need to turn it into a c-style string first
    char* c_comment = new char[(comment_len+1)];
    
    memcpy(c_comment,fort_comment,comment_len);
    c_comment[comment_len]='\0';
    
    comment_str = c_comment;
    delete[] c_comment;
    return comment_str;
}
//---------------------------------------------------------------------------//
/**
 * \brief Sets up a DAGMC mesh tally in Fortran
 * \param ipt the type of particle; currently unused
 * \param id the unique ID for the tally defined by FMESH
 * \param energy_mesh the energy bin boundaries
 * \param n_energy_mesh the number of energy bin boundaries
 * \param tot_energy_bin determines if total energy bin was requested
 * \param fort_comment the FC card comment
 * \param n_comment_lines the number of comment lines
 * \param is_collision_tally indicates that tally uses collision estimator
 */
void dagmc_fmesh_setup_mesh_(int* /*ipt*/, int* id, 
                             double* energy_mesh, int* n_energy_mesh,
                             int* tot_energy_bin, 
                             char* fort_comment, int* n_comment_lines,
                             int* is_collision_tally)
{
    std::cout << "Mesh tally " << *id << " has these " << *n_energy_mesh
              << " energy bins: " << std::endl;

    for(int i = 0; i < *n_energy_mesh; ++i)
    {
        std::cout << "     " << energy_mesh[i] << std::endl;
    }

    // TODO: Total energy bin is currently always on unless one bin is used
    std::cout << "tot bin: " << (*tot_energy_bin ? "yes" : "no") << std::endl;

    if(*n_comment_lines <= 0)
    {
        std::cerr << "FMESH" << *id
                  << " has geom=dag without matching FC card" << std::endl;
        exit(EXIT_FAILURE);
    }
  
    // Copy emesh bin boundaries from MCNP (includes 0.0 MeV)
    std::vector<double> emesh_boundaries;
    for(int i = 0; i < *n_energy_mesh; ++i)
    {
        emesh_boundaries.push_back(energy_mesh[i]);
    }

    // Parse FC card and create input data for MeshTally
    std::multimap<std::string, std::string> fc_settings;
    std::string comment_str = copyComments(fort_comment, n_comment_lines);
    parse_fc_card(comment_str, fc_settings, *id);

    // determine the user-specified tally type
    std::string type = "unstr_track";

    if(fc_settings.find("type") != fc_settings.end())
    {
        type = (*fc_settings.find("type")).second;

        if(fc_settings.count("type") > 1)
        {
            std::cerr << "Warning: FC" << *id
                      << " has multiple 'type' keywords, using " << type << std::endl;
        }

        // remove the type keywords
        fc_settings.erase("type"); 
    }
     
    // Set whether the tally type is a collision tally 
    if (type.find("coll") != std::string::npos)
    {
        *is_collision_tally = true;
    }
    else
    {
        *is_collision_tally = false;
    } 

    tallyManager.addNewTally(*id, type, emesh_boundaries, fc_settings);
}
//---------------------------------------------------------------------------//
// RUNTAPE AND MPI METHODS
//---------------------------------------------------------------------------//
/**
 * Get a fortran pointer to the tally array for the specified mesh tally.
 * Called when this data needs to be written or read from a runtpe file or 
 * an MPI stream.
 */
void dagmc_fmesh_get_tally_data_( int* tally_id, void* fortran_data_pointer )
{
  double* data; 
  int length;
 
  data = tallyManager.get_tally_data(*tally_id, length);
  FMESH_FUNC( dagmc_make_fortran_pointer )( fortran_data_pointer, data, &length );
}

/**
 * Get a fortran pointer to the error array for the specified mesh tally.
 * Called when this data needs to be written or read from a runtpe file or 
 * an MPI stream.
 */
void dagmc_fmesh_get_error_data_( int* tally_id, void* fortran_data_pointer )
{
  double* data; 
  int length;
 
  data = tallyManager.get_error_data(*tally_id, length);
  FMESH_FUNC( dagmc_make_fortran_pointer )( fortran_data_pointer, data, &length );
}

/**
 * Get a fortran pointer to the scratch array for the specified mesh tally.
 * Called when this data needs to be written or read from a runtpe file or 
 * an MPI stream.
 */
void dagmc_fmesh_get_scratch_data_( int* tally_id, void* fortran_data_pointer )
{
  double* data; 
  int length;
  
  data = tallyManager.get_scratch_data(*tally_id, length);
  FMESH_FUNC( dagmc_make_fortran_pointer )( fortran_data_pointer, data, &length );
}

/**
 * Set the tally and error arrays of the specified mesh tally to all zeros.
 * Called when an MPI subtask has just sent all its tally and error values
 * back to the master task.
 */
void dagmc_fmesh_clear_data_()
{
   tallyManager.zero_all_tally_data();
}

/**
 * Add the values in this mesh's scratch array to its tally array.
 * Called when merging together values from MPI subtasks at the master task.
 */
void dagmc_fmesh_add_scratch_to_tally_( int* tally_id )
{
  double* data; 
  double* scratch;
  int length, scratchlength;

  data = tallyManager.get_tally_data(*tally_id, length);
  scratch = tallyManager.get_scratch_data(*tally_id, scratchlength);
  
  assert( scratchlength >= length );

  for( int i = 0; i < length; ++i )
  {
      data[i] += scratch[i];
  }
}
/**
 * Add the values in this mesh's scratch array to its error array.
 * Called when merging together values from MPI subtasks at the master task.
 */
void dagmc_fmesh_add_scratch_to_error_( int* tally_id )
{
  double* error_data; 
  double* scratch;
  int length, scratchlength;

  error_data = tallyManager.get_error_data(*tally_id, length);
  scratch = tallyManager.get_scratch_data(*tally_id, scratchlength);
  
  assert( scratchlength >= length );

  for( int i = 0; i < length; ++i )
  {
     error_data[i] += scratch[i];
  }
}
//---------------------------------------------------------------------------//
// ROUTINE FMESH METHODS
//---------------------------------------------------------------------------//
/**
 * \brief Called from fortran when a particle history ends
 */
void dagmc_fmesh_end_history_()
{
    tallyManager.end_history();

#ifdef MESHTAL_DEBUG
    std::cout << "* History ends *" << std::endl;
#endif
}

//---------------------------------------------------------------------------//
/**
 * \brief Called from fortran to score a track event
 * \param x, y, z the position of the particle
 * \param u, v, w the direction of the particle
 * \param erg the energy of the particle
 * \param wgt the weight of the particle
 * \param d the track length
 * \param icl the current cell ID (MCNP global variable)
 */
void dagmc_fmesh_score_(double *x, double *y, double *z,
                        double *u, double *v, double *w, 
                        double *erg,double *wgt, 
                        double *d, int *icl)
{
#ifdef MESHTAL_DEBUG
    std::cout << "particle loc: " << *x << ", " << *y << ", " << *z << std::endl;
    std::cout << "particle dir: " << *u << ", " << *v << ", " << *w << std::endl;
    std::cout << "track length: " << *d << std::endl;
#endif

    tallyManager.set_track_event(*x, *y, *z, *u, *v, *w, *erg, *wgt, *d, *icl);
    tallyManager.update_tallies();
}
//---------------------------------------------------------------------------//
/**
 * \brief Called from fortran to instruct tallies to print data to file
 * \param sp_norm "Source Particle Normalization", number of source particles
 */
void dagmc_fmesh_print_(double* sp_norm)
{
    tallyManager.write_data(*sp_norm);
}
//---------------------------------------------------------------------------//
/**
 * \brief Called from hstory.F90 to score a collision event
 * \param x, y, z the position of the particle
 * \param erg the energy of the particle
 * \param wgt the weight of the particle
 * \param ple the total macroscopic cross section of the current cell
 * \param icl the current cell ID (MCNP global variable)
 */
void dagmc_collision_score_(double* x,   double* y, double* z, 
                            double* erg, double* wgt,
                            double* ple, int* icl)
{
    tallyManager.set_collision_event(*x, *y, *z, *erg, *wgt, *ple, *icl);
    tallyManager.update_tallies();
}
//---------------------------------------------------------------------------//

// end of MCNP5/dagmc/meshtal_funcs.cpp
