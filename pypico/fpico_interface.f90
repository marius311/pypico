
module fpico

    ! Manually make sure our C types and Fortran types are the same size
    ! See corresponding line in pico.pyx
    integer, parameter :: fpint = 8
    integer, parameter :: fpreal = 8

    interface


        ! This must be called before calling any other PICO interface functions.
        !
        ! Parameters:
        ! -----------
        !   _kill_on_error : fpint
        !       Set to True to kill the program immediately on a Python error and print
        !       an error message, or set to False to do your own error handling by
        !       using `Py_CheckError`.
        !
        subroutine fpico_init(kill_on_error)
            import :: fpint
            integer(fpint), intent(in) :: kill_on_error
        end



        ! Load a PICO data file. Only one datafile can be loaded at a time.
        !
        ! Parameters:
        ! -----------
        ! file : character(len=*)
        !     The filename
        !
        subroutine fpico_load(filename)
            character(len=*), intent(in) :: filename
        end


        ! Reset the parameters to be passed to PICO.
        subroutine fpico_reset_params()
        end


        ! Set a PICO parameter to a real.
        !
        ! Parameters:
        ! -----------
        ! name : character(len=*)
        !     Parameter name
        ! value : fpreal
        !     Parameter value
        subroutine fpico_set_param(name,value)
            import :: fpreal
            character(len=*), intent(in) :: name
            real(fpreal), intent(in) :: value
        end


        ! Set a PICO parameter to a Python expression.
        !
        ! Parameters:
        ! -----------
        ! name : character(len=*)
        !     Parameter name
        ! value : character(len=*)
        !     Parameter value, which will be passed through Python's `eval`.
        subroutine fpico_set_param_eval(name,value)
            import :: fpreal
            character(len=*), intent(in) :: name, value
        end


        ! Reset the outputs requested from PICO.
        subroutine fpico_reset_requested_outputs()
        end

        ! Add an output the requested outputs from PICO.
        ! 
        ! Parameters:
        ! -----------
        ! name : character(len=*)
        !     Name of requested output
        subroutine fpico_request_output(name)
            character(len=*), intent(in) :: name
        end


        ! Call PICO on the parameters which have been set 
        ! with `fpico_set_param` and for the outputs requested 
        ! with `fpico_request_output`.
        ! 
        ! Returns:
        ! -----------
        ! success : fpint
        !     Non-zero if successful.
        subroutine fpico_compute_result(success)
            import :: fpint
            integer(fpint), intent(out) :: success
        end subroutine


        ! Get the maximum length of an output array.
        ! 
        ! Parameters:
        ! -----------
        ! name : character(len=*)
        !     The name of the output.
        ! 
        ! Returns:
        ! --------
        ! length : fpint
        !     The length of the output array.
        subroutine fpico_get_output_len(name,length)
            import :: fpint
            character(len=*), intent(in) :: name
            integer(fpint), intent(out) :: length
        end subroutine

        ! Read an output array from the computed PICO result.
        !
        ! Parameters:
        ! -----------
        ! name : character(len=*)
        !     The name of the output.
        ! istart, iend : fpint
        !     Read the array from istart:iend.
        ! 
        ! Returns:
        ! --------
        ! output : fpreal, dimension(istart:iend)
        !     The output array is read into here.
        subroutine fpico_read_output(name,output,istart,iend)
            import :: fpint, fpreal
            character(len=*), intent(in) :: name
            integer(fpint), intent(in) :: istart, iend
            real(fpreal), dimension(istart:iend), intent(out) :: output
        end subroutine


        subroutine fpico_set_verbose(verbose)
            import :: fpint
            integer(fpint), intent(in) :: verbose
        end subroutine

    end interface

end module
