{ lib, buildPythonPackage, fetchFromGitHub, python311Packages, python }:

buildPythonPackage rec {
  pname = "image-processing";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "badele";
    repo = "fork-Image-Processing";
    rev = "main";
    sha256 = "sha256-1a/il1R1eMmwcjmSOUP8f23nBkP90IZoKhxUPo+fPrk=";
  };

  propagatedBuildInputs = with python311Packages; [
    moderngl
    numpy
    pillow
    pygame
  ];

  meta = with lib; {
    description =
      "An OpenGL image processing Python library that works with any type of textures";
    homepage = "https://github.com/gBloxy/Image-Processing";
    license = licenses.mit;
  };
}

