
module fpico

    ! Manually make sure our C types and Fortran types are the same size
    ! See corresponding line in pico.pyx
    integer, parameter :: fpint = 8
    integer, parameter :: fpreal = 8

    interface

        subroutine fpico_init(kill_on_error)
            import :: fpint
            integer(fpint), intent(in) :: kill_on_error
        end


        subroutine fpico_load(filename)
            character(len=*), intent(in) :: filename
        end


        subroutine fpico_reset_params()
        end


        subroutine fpico_set_param(name,value)
            import :: fpreal
            character(len=*), intent(in) :: name
            real(fpreal), intent(in) :: value
        end


        subroutine fpico_reset_requested_outputs()
        end


        subroutine fpico_request_output(name)
            character(len=*), intent(in) :: name
        end


        subroutine fpico_compute_result(success)
            import :: fpint
            integer(fpint), intent(out) :: success
        end subroutine


        subroutine fpico_get_output_len(name,length)
            import :: fpint
            character(len=*), intent(in) :: name
            integer(fpint), intent(out) :: length
        end subroutine


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
