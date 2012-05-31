module fpico


    interface
        function fpico_compute_result_()
            logical :: fpico_compute_result_
        end function
    end interface

contains

    subroutine fpico_load(file)
        character(len=*) :: file
        print *, "Loading PICO..."
        call fpico_load_(file,len(file))
    end subroutine


    subroutine fpico_set_param(name,value)
        character(len=*) :: name
        real(8) :: value
        call fpico_set_param_(name,len(name),value)
    end subroutine


    function fpico_compute_result()
        logical :: fpico_compute_result
        fpico_compute_result = fpico_compute_result_()
    end function


    function fpico_read_result(which, istart, iend)
        character(len=*) :: which
        integer :: istart, iend
        real(8), dimension(istart:iend) :: fpico_read_result
        call fpico_read_result_(which, len(which), fpico_read_result, istart, iend)
    end function


    function fpico_has_output(output)
        character(len=*) :: output
        logical :: fpico_has_output

        print *, int(fpico_has_output_(output,len(output)),8)
        fpico_has_output = (fpico_has_output_(output,len(output)) == 0)
    end function


end module
