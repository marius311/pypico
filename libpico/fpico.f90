module fpico

    use CAMBmain
    use ModelParams
    use ModelData
    use CAMB

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


    subroutine Pico_GetResults(P, error)
        type(CAMBparams) :: P
        integer, optional :: error !Zero if OK
        real(8) :: fac

        call CAMBParams_Set(P)

        call fpico_set_param("ombh2", p%omegab*(p%H0/100.)**2)
        call fpico_set_param("omch2", p%omegac*(p%H0/100.)**2)
        call fpico_set_param("omnuh2", p%omegan*(p%H0/100.)**2)
        call fpico_set_param("omvh2", p%omegav*(p%H0/100.)**2)
        call fpico_set_param("omk", p%omegak)
        call fpico_set_param("hubble", p%H0)
        call fpico_set_param("w", real(w_lam,8))
        call fpico_set_param("theta", CosmomcTheta())
        call fpico_set_param("helium_fraction", p%yhe)
        call fpico_set_param("massless_neutrinos", p%Num_Nu_massless)
        call fpico_set_param("massive_neutrinos", real(p%Num_Nu_massive,8))
        call fpico_set_param("scalar_spectral_index(1)",p%InitPower%an(1))
        call fpico_set_param("tensor_spectral_index(1)",p%InitPower%ant(1))
        call fpico_set_param("scalar_nrun(1)",p%InitPower%n_run(1))
        call fpico_set_param("initial_ratio(1)",p%InitPower%rat(1))
        call fpico_set_param("scalar_amp(1)",p%InitPower%ScalarPowerAmp(1))
        call fpico_set_param("pivot_scalar",p%InitPower%k_0_scalar)
        call fpico_set_param("re_optical_depth",p%Reion%optical_depth)

        if (fpico_compute_result()) then
            if (allocated(Cl_scalar)) deallocate(Cl_scalar)
            if (allocated(Cl_tensor)) deallocate(Cl_tensor)
            if (allocated(Cl_lensed)) deallocate(Cl_lensed)
            allocate(Cl_scalar(lmin:P%Max_l,1,C_Temp:C_last))
            allocate(Cl_tensor(lmin:P%Max_l_tensor,1,CT_Temp:CT_Cross))
            allocate(Cl_lensed(lmin:P%Max_l,1,CT_Temp:CT_Cross))

            Cl_scalar(:,1,C_Temp) = fpico_read_result("scalar_TT",lmin,P%Max_l)
            Cl_scalar(:,1,C_Cross) = fpico_read_result("scalar_TE",lmin,P%Max_l)
            Cl_scalar(:,1,C_E) = fpico_read_result("scalar_EE",lmin,P%Max_l)
            Cl_tensor(:,1,CT_Temp) = fpico_read_result("tensor_TT",lmin,P%Max_l_tensor)
            Cl_tensor(:,1,CT_Cross) = fpico_read_result("tensor_TE",lmin,P%Max_l_tensor)
            Cl_tensor(:,1,CT_E) = fpico_read_result("tensor_EE",lmin,P%Max_l_tensor)
            Cl_tensor(:,1,CT_B) = fpico_read_result("tensor_BB",lmin,P%Max_l_tensor)
            Cl_lensed(:,1,CT_Temp) = fpico_read_result("lensed_TT",lmin,P%Max_l)
            Cl_lensed(:,1,CT_Cross) = fpico_read_result("lensed_TE",lmin,P%Max_l)
            Cl_lensed(:,1,CT_E) = fpico_read_result("lensed_EE",lmin,P%Max_l)
            Cl_lensed(:,1,CT_B) = fpico_read_result("lensed_BB",lmin,P%Max_l)

            fac = (2.726e6)**2
            Cl_scalar = Cl_scalar / fac
            Cl_tensor = Cl_tensor / fac
            Cl_lensed = Cl_lensed / fac
        else
            call CAMB_GetResults(P,error)
        end if

    end subroutine



end module
